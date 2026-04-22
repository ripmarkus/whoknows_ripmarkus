# frozen_string_literal: true

require 'sinatra'
require 'sequel'
require 'json'
require 'bcrypt'
require 'net/http'
require 'uri'
require 'dotenv/load'
require 'prometheus/client'
require 'prometheus/client/formats/text'

enable :sessions

set :protection, except: :host_authorization

# Handle database connection for test environment
if ENV['RACK_ENV'] == 'test'
  # In test mode, change to the ruby-app directory for relative SQLite paths
  Dir.chdir(__dir__)
end

DB = Sequel.connect(ENV.fetch('DATABASE_URL'))

# Monitoring Metrics
PROM_REGISTRY = Prometheus::Client.registry

HTTP_REQUESTS_TOTAL = PROM_REGISTRY.counter(
  :http_requests_total,
  docstring: 'Total number of HTTP requests',
  labels: %i[method path status]
)

HTTP_REQUEST_DURATION_SECONDS = PROM_REGISTRY.histogram(
  :http_request_duration_seconds,
  docstring: 'HTTP request duration in seconds',
  labels: %i[method path status],
  buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2, 5]
)

HTTP_REQUEST_EXCEPTIONS_TOTAL = PROM_REGISTRY.counter(
  :http_request_exceptions_total,
  docstring: 'Total number of exceptions raised while handling requests',
  labels: %i[path]
)

USER_LOGINS_TOTAL = PROM_REGISTRY.counter(
  :user_logins_total,
  docstring: 'Total successful user logins'
)

USER_LOGIN_FAILURES_TOTAL = PROM_REGISTRY.counter(
  :user_login_failures_total,
  docstring: 'Total failed user login attempts'
)

USER_REGISTRATIONS_TOTAL = PROM_REGISTRY.counter(
  :user_registrations_total,
  docstring: 'Total successful user registrations'
)

PASSWORD_CHANGES_TOTAL = PROM_REGISTRY.counter(
  :password_changes_total,
  docstring: 'Total successful password changes'
)

PASSWORD_CHANGE_FAILURES_TOTAL = PROM_REGISTRY.counter(
  :password_change_failures_total,
  docstring: 'Total failed password change attempts',
  labels: %i[reason]
)

SEARCH_QUERIES_TOTAL = PROM_REGISTRY.counter(
  :search_queries_total,
  docstring: 'Total number of search queries',
  labels: %i[language result]
)

SEARCH_RESULT_COUNT = PROM_REGISTRY.histogram(
  :search_result_count,
  docstring: 'Number of search results returned per query',
  labels: %i[language],
  buckets: [0, 1, 2, 5, 10, 20, 50, 100]
)

WEATHER_API_REQUESTS_TOTAL = PROM_REGISTRY.counter(
  :weather_api_requests_total,
  docstring: 'Total number of outbound requests to the OpenWeather API',
  labels: %i[status]
)

WEATHER_API_REQUEST_DURATION_SECONDS = PROM_REGISTRY.histogram(
  :weather_api_request_duration_seconds,
  docstring: 'Duration of outbound requests to the OpenWeather API in seconds',
  labels: %i[status],
  buckets: [0.05, 0.1, 0.25, 0.5, 1, 2, 5, 10]
)

# XSS (Cross-site scripting) sanitizes html output to prevent malicious scripts from being executed in the browser
helpers do
  include Rack::Utils
  alias_method :h, :escape_html
end

# JSON helper - sets default content type to json and parses response body as json, with error handling
def http_get_json(uri)
  res = Net::HTTP.get_response(uri)
  body = res.body.to_s

  begin
    parsed = JSON.parse(body)
  rescue JSON::ParserError
    parsed = { 'raw' => body }
  end

  [res.code.to_i, parsed]
end

before do
  env['metrics.request_started_at'] = Process.clock_gettime(Process::CLOCK_MONOTONIC)

  if session[:user_id] && !['/change-password', '/logout', '/api/logout'].include?(request.path_info)
    user = DB[:users].where(id: session[:user_id]).select(:password_reset_required).first
    redirect '/change-password' if user && user[:password_reset_required] == 1
  end
end

def metrics_path_label(env)
  route = env['sinatra.route']
  route ? route.split(' ', 2).last : 'unknown'
end

after do
  next if request.path_info == '/metrics'

  started_at = env['metrics.request_started_at']
  next unless started_at

  duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at
  path_label = metrics_path_label(env)

  HTTP_REQUESTS_TOTAL.increment(
    labels: {
      method: request.request_method,
      path: path_label,
      status: response.status.to_s
    }
  )

  HTTP_REQUEST_DURATION_SECONDS.observe(
    duration,
    labels: {
      method: request.request_method,
      path: path_label,
      status: response.status.to_s
    }
  )
end

error do
  HTTP_REQUEST_EXCEPTIONS_TOTAL.increment(
    labels: { path: metrics_path_label(env) }
  )
  env['sinatra.error']
end

###############
# VIEWS
###############

get '/' do
  query    = params[:query]
  language = params[:language] || 'en'

  if query.nil?
    erb :home
  else
    search_results = search_pages_query(language, query)
    result_label = search_results.empty? ? 'miss' : 'hit'

    SEARCH_QUERIES_TOTAL.increment(
      labels: { language: language, result: result_label }
    )

    SEARCH_RESULT_COUNT.observe(
      search_results.length,
      labels: { language: language }
    )

    erb :search, locals: { search_results: search_results, query: query }
  end
end

get '/about' do
  erb :about
end

get '/login' do
  erb :login, locals: { error: nil }
end

get '/register' do
  erb :register, locals: { error: nil }
end

get '/api/docs' do
  spec_url = '/api-docs/openapi.yaml'
  erb :openapi, locals: { spec_url: spec_url }, layout: false
end

get '/api/docs/openapi.yaml' do
  content_type 'text/yaml'
  send_file File.join(settings.root, 'OpenAPI', 'OpenAPI.yaml')
end

MONITORING_IP = ENV['MONITORING_IP'].to_s.strip

get '/metrics' do
  halt 403, 'Forbidden' unless request.ip == MONITORING_IP
  content_type 'text/plain; version=0.0.4; charset=utf-8'
  Prometheus::Client::Formats::Text.marshal(PROM_REGISTRY)
end

###############
# SHARED LOGIC
###############

def get_user_id(username)
  user = DB[:users].where(username: username).select(:id).first
  user ? user[:id] : nil
end

def search_pages_query(language, query)
  return [] if query.to_s.strip.empty?

  # SQLite doesn't support full-text search with @@ operator
  # Use simple LIKE search instead for SQLite compatibility
  search_term = "%#{query}%"
  DB[:pages]
    .where(language: language)
    .where(Sequel.like(:content, search_term) | Sequel.like(:title, search_term))
    .select(:title, :url, :language, :last_updated, :content)
    .all
end

def authenticate_user(username, password)
  user = DB[:users].where(username: username).first
  return [nil, 'Invalid credentials'] if user.nil?
  return [nil, 'Invalid credentials'] unless password_matches?(user[:password], password)

  [user, nil]
end

def validate_registration_fields(params)
  return 'You have to enter a username' if params[:username].nil? || params[:username].empty?
  return 'Valid email address needed' if params[:email].nil? || !params[:email].include?('@')
  return 'You have to enter a password' if params[:password].to_s.strip.empty?
  return 'The two passwords do not match' if params[:password] != params[:password2]

  nil
end

def validate_registration(params)
  error = validate_registration_fields(params)
  return error if error

  return 'The username already exists' if get_user_id(params[:username])

  'The email already exists' if DB[:users].where(email: params[:email]).first
end

def register_user(params)
  hashed_pw = hash_password(params[:password])
  DB[:users].insert(username: params[:username], email: params[:email], password: hashed_pw)
  session[:user_id] = get_user_id(params[:username])
  session[:username] = params[:username]
end

###############
# HTML ROUTES
###############

post '/login' do
  user, error = authenticate_user(params[:username], params[:password])

  if error
    USER_LOGIN_FAILURES_TOTAL.increment
    erb :login, locals: { error: error }
  else
    USER_LOGINS_TOTAL.increment
    session[:user_id] = user[:id]
    session[:username] = user[:username]
    redirect '/'
  end
end

post '/register' do
  redirect '/' if session[:user_id]

  error = validate_registration(params)

  if error
    erb :register, locals: { error: error }
  else
    register_user(params)
    USER_REGISTRATIONS_TOTAL.increment
    redirect '/'
  end
end

get '/change-password' do
  redirect '/login' unless session[:user_id]
  erb :change_password, locals: { error: nil }
end

post '/change-password' do
  redirect '/login' unless session[:user_id]

  user = DB[:users].where(id: session[:user_id]).first
  halt 403 unless user

  unless password_matches?(user[:password], params[:current_password])
    PASSWORD_CHANGE_FAILURES_TOTAL.increment(labels: { reason: 'wrong_current' })
    return erb :change_password, locals: { error: 'Current password is incorrect' }
  end

  if params[:new_password].to_s.strip.empty?
    PASSWORD_CHANGE_FAILURES_TOTAL.increment(labels: { reason: 'empty_new' })
    return erb :change_password, locals: { error: 'New password cannot be empty' }
  end

  if params[:new_password] != params[:new_password2]
    PASSWORD_CHANGE_FAILURES_TOTAL.increment(labels: { reason: 'mismatch' })
    return erb :change_password, locals: { error: 'New passwords do not match' }
  end

  hashed = hash_password(params[:new_password])
  DB[:users].where(id: session[:user_id]).update(password: hashed, password_reset_required: 0)
  PASSWORD_CHANGES_TOTAL.increment

  redirect '/'
end

post '/logout' do
  session.delete(:user_id)
  session[:flash] = 'You were logged out'
  redirect '/'
end

###############
# API ENDPOINTS
###############

get '/api/users' do
  content_type :json
  DB[:users].select(:id, :username, :email).all.to_json
end

get '/api/search' do
  content_type :json
  query    = params[:query]
  language = params[:language] || 'en'
  search_results = query ? search_pages_query(language, query) : []

  unless query.nil?
    result_label = search_results.empty? ? 'miss' : 'hit'

    SEARCH_QUERIES_TOTAL.increment(
      labels: { language: language, result: result_label }
    )

    SEARCH_RESULT_COUNT.observe(
      search_results.length,
      labels: { language: language }
    )
  end

  { message: 'Search endpoint hit', results: search_results }.to_json
end

post '/api/login' do
  content_type :json
  user, error = authenticate_user(params[:username], params[:password])

  if error
    USER_LOGIN_FAILURES_TOTAL.increment
    halt 401, { error: error }.to_json
  end

  USER_LOGINS_TOTAL.increment
  session[:user_id] = user[:id]
  session[:username] = user[:username]
  { message: 'Login successful', username: user[:username] }.to_json
end

post '/api/register' do
  content_type :json
  halt 400, { error: 'Already logged in' }.to_json if session[:user_id]

  error = validate_registration(params)

  if error
    halt 400, { error: error }.to_json
  end

  register_user(params)
  USER_REGISTRATIONS_TOTAL.increment
  { message: 'Registration successful', username: params[:username] }.to_json
end

post '/api/logout' do
  content_type :json
  session.delete(:user_id)
  { message: 'Logout successful' }.to_json
end

###############
# SECURITY
###############

def hash_password(password)
  BCrypt::Password.create(password)
end

def password_matches?(password_hash, plaintext_password)
  BCrypt::Password.new(password_hash) == plaintext_password
end

###############
# WEATHER
###############

def fetch_geocoding(location_query, api_key)
  uri = URI("https://api.openweathermap.org/geo/1.0/direct?q=#{URI.encode_www_form_component(location_query)}&limit=1&appid=#{api_key}")
  http_get_json(uri)
end

def fetch_weather(latitude, longitude, api_key)
  uri = URI("https://api.openweathermap.org/data/2.5/weather?lat=#{latitude}&lon=#{longitude}&units=metric&lang=da&appid=#{api_key}")
  http_get_json(uri)
end

def resolve_location(location_query, api_key)
  status, result = fetch_geocoding(location_query, api_key)
  return [status, { 'error' => 'geocoding failed', 'details' => result }] unless status == 200
  return [404, { 'error' => 'no location found', 'query' => location_query }] unless result.is_a?(Array) && result.any?

  location = result.first
  lat = location['lat']
  lon = location['lon']
  return [502, { 'error' => 'no lat/lon', 'location' => location }] if lat.nil? || lon.nil?

  [200, location]
end

# Weather function - gets lat/lon for city/country and then gets weather for that location
def get_weather_for(city:, country:, api_key:)
  started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)

  location_query = country.strip.empty? ? city : "#{city},#{country}"

  status, location = resolve_location(location_query, api_key)
  unless status == 200
    WEATHER_API_REQUESTS_TOTAL.increment(labels: { status: status.to_s })
    WEATHER_API_REQUEST_DURATION_SECONDS.observe(
      Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at,
      labels: { status: status.to_s }
    )
    return [status, location]
  end

  weather_status, weather_data = fetch_weather(location['lat'], location['lon'], api_key)
  unless weather_status == 200
    WEATHER_API_REQUESTS_TOTAL.increment(labels: { status: weather_status.to_s })
    WEATHER_API_REQUEST_DURATION_SECONDS.observe(
      Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at,
      labels: { status: weather_status.to_s }
    )
    return [weather_status, { 'error' => 'weather fetch failed', 'details' => weather_data }]
  end

  WEATHER_API_REQUESTS_TOTAL.increment(labels: { status: '200' })
  WEATHER_API_REQUEST_DURATION_SECONDS.observe(
    Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at,
    labels: { status: '200' }
  )

  [200, { 'location' => location, 'weather' => weather_data }]
end

# Shows the weather page for a given city and country, using the OpenWeather API, with error handling
# Example: /weather?city=København&country=DK
get '/weather' do
  api_key = ENV['OPENWEATHER_API_KEY'].to_s.strip
  halt 500, 'Missing OPENWEATHER_API_KEY' if api_key.empty?

  city    = params.fetch(:city, 'København').to_s.strip
  country = params.fetch(:country, '').to_s.strip

  status, payload = get_weather_for(city: city, country: country, api_key: api_key)
  halt status, payload.to_json unless status == 200

  @loc = payload['location']
  @w   = payload['weather']
  erb :weather
end

# Example: /api/weather?city=København&country=DK
# Gets weather data for a given city within a country, using the OpenWeather API, with error handling and JSON response
get '/api/weather' do
  content_type :json
  api_key = ENV['OPENWEATHER_API_KEY'].to_s.strip
  halt 500, { error: 'Missing OPENWEATHER_API_KEY' }.to_json if api_key.empty?

  city    = params.fetch(:city, 'København').to_s.strip
  country = params.fetch(:country, '').to_s.strip

  status, payload = get_weather_for(city: city, country: country, api_key: api_key)
  halt status, payload.to_json unless status == 200

  payload.to_json
end
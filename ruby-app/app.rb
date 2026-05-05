# frozen_string_literal: true

require 'sinatra'
require 'sequel'
require 'json'
require 'bcrypt'
require 'net/http'
require 'uri'
require 'logger'
require 'fileutils'
require 'ipaddr'
require 'dotenv/load'
require 'prometheus/client'
require 'prometheus/client/formats/text'

configure do
  enable :sessions
  set :show_exceptions, false
  set :protection, except: :host_authorization

  FileUtils.mkdir_p('logs')
  LOGGER = Logger.new('logs/app.log')

  Dir.chdir(__dir__) if ENV['RACK_ENV'] == 'test'

  DB = Sequel.connect(ENV.fetch('DATABASE_URL'))

  PROM_REGISTRY = Prometheus::Client.registry
end

def fetch_or_register_counter(registry, name, docstring:, labels: [])
  registry.get(name) || registry.counter(name, docstring:, labels:)
rescue Prometheus::Client::Registry::AlreadyRegisteredError
  registry.get(name)
end

def fetch_or_register_histogram(registry, name, docstring:, labels:, buckets:)
  registry.get(name) || registry.histogram(name, docstring:, labels:, buckets:)
rescue Prometheus::Client::Registry::AlreadyRegisteredError
  registry.get(name)
end

HTTP_REQUESTS_TOTAL = fetch_or_register_counter(
  PROM_REGISTRY,
  :http_requests_total,
  docstring: 'Total number of HTTP requests',
  labels: %i[method path status_code]
)

HTTP_REQUEST_DURATION_SECONDS = fetch_or_register_histogram(
  PROM_REGISTRY,
  :http_request_duration_seconds,
  docstring: 'HTTP request duration in seconds',
  labels: %i[method path status_code],
  buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2, 5]
)

HTTP_REQUEST_ERRORS_TOTAL = fetch_or_register_counter(
  PROM_REGISTRY,
  :http_request_errors_total,
  docstring: 'Total number of HTTP request failures',
  labels: %i[method path error_class]
)

LOGIN_ATTEMPTS_TOTAL = fetch_or_register_counter(
  PROM_REGISTRY,
  :login_attempts_total,
  docstring: 'Total login attempts',
  labels: %i[result]
)

REGISTRATIONS_TOTAL = fetch_or_register_counter(
  PROM_REGISTRY,
  :registrations_total,
  docstring: 'Total registrations',
  labels: %i[result]
)

PASSWORD_CHANGES_TOTAL = fetch_or_register_counter(
  PROM_REGISTRY,
  :password_changes_total,
  docstring: 'Total password change attempts',
  labels: %i[result]
)

SEARCH_QUERIES_TOTAL = fetch_or_register_counter(
  PROM_REGISTRY,
  :search_queries_total,
  docstring: 'Total number of search queries',
  labels: %i[language hit]
)

SEARCH_DURATION_SECONDS = fetch_or_register_histogram(
  PROM_REGISTRY,
  :search_duration_seconds,
  docstring: 'Search request duration in seconds',
  labels: %i[language hit],
  buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2]
)

WEATHER_API_REQUESTS_TOTAL = fetch_or_register_counter(
  PROM_REGISTRY,
  :weather_api_requests_total,
  docstring: 'Total number of outbound requests to the OpenWeather API',
  labels: %i[phase status_code]
)

WEATHER_API_DURATION_SECONDS = fetch_or_register_histogram(
  PROM_REGISTRY,
  :weather_api_duration_seconds,
  docstring: 'Duration of outbound OpenWeather API requests in seconds',
  labels: %i[phase status_code],
  buckets: [0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2, 5]
)

WEATHER_API_ERRORS_TOTAL = fetch_or_register_counter(
  PROM_REGISTRY,
  :weather_api_errors_total,
  docstring: 'Total number of outbound OpenWeather API errors',
  labels: %i[phase error_class]
)

def payload_value(payload, key)
  payload[key.to_s] || payload[key.to_sym]
end

def hash_password(password)
  BCrypt::Password.create(password)
end

def password_matches?(password_hash, plaintext_password)
  BCrypt::Password.new(password_hash) == plaintext_password
rescue BCrypt::Errors::InvalidHash
  false
end

def validate_registration_fields(payload)
  username = payload_value(payload, :username).to_s
  email = payload_value(payload, :email).to_s
  password = payload_value(payload, :password).to_s
  password2 = payload_value(payload, :password2).to_s

  return 'You have to enter a username' if username.strip.empty?
  return 'Valid email address needed' if email.strip.empty? || !email.include?('@')
  return 'You have to enter a password' if password.strip.empty?
  return 'The two passwords do not match' if password != password2

  nil
end

# FIX 3: Extracted shared search logic into a helper to avoid duplication
# between the HTML route (GET /) and the API route (GET /api/search).
# FIX 1: Added Postgres/SQLite fallback so tests running against SQLite don't crash.
# FIX 2: ORDER BY uses expressions directly instead of aliases, so the order
#         is not lost when .select() later drops the appended rank columns.
def apply_search_filters(dataset, query, language)
  lang_map = { 'en' => 'english', 'da' => 'danish' }
  pg_language = lang_map[language] || 'english'

  rank_title = Sequel.case({ true => 2 }, 0, Sequel.function(:lower, :title) => query.downcase)

  if DB.database_type == :postgres
    ts_query = Sequel.function(:plainto_tsquery, pg_language, query)
    rank_fts = Sequel.function(:ts_rank, :search_vector, ts_query)
    dataset = dataset.where(Sequel.lit('search_vector @@ ?', ts_query))
    dataset = dataset.select_append(rank_title.as(:rank_title), rank_fts.as(:rank_fts))
    dataset = dataset.order(Sequel.desc(rank_title), Sequel.desc(rank_fts))
  else
    like_query = "%#{query.downcase}%"
    title_match = Sequel.function(:lower, :title).like(like_query)
    content_match = Sequel.function(:lower, :content).like(like_query)
    dataset = dataset.where(Sequel.|(title_match, content_match))
    dataset = dataset.select_append(rank_title.as(:rank_title))
    dataset = dataset.order(Sequel.desc(rank_title))
  end

  dataset
end

helpers do
  include Rack::Utils
  alias_method :h, :escape_html

  def json(payload = nil, status_code: nil, **kwargs)
    response_payload = payload || kwargs
    content_type :json
    status status_code if status_code
    response_payload.to_json
  end

  def monotonic_now
    Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end

  def parsed_json_body
    body = request.body.read.to_s
    request.body.rewind
    JSON.parse(body)
  rescue JSON::ParserError
    {}
  end

  def request_payload
    if request.media_type.to_s.include?('application/json')
      parsed_json_body
    else
      params
    end
  end

  def metrics_path_label(env)
    route = env['sinatra.route']
    return '/unknown' if route.nil? || route.strip.empty?

    _method, path = route.split(' ', 2)
    normalized = path.to_s.strip
    normalized.empty? ? '/unknown' : normalized
  end

  def skip_http_metrics?(env)
    path = metrics_path_label(env)

    request.path_info == '/metrics' ||
      path == '/api/weather' ||
      path == '/weather'
  end

  def allowed_ip?(request_ip, allowed)
    return false if allowed.to_s.strip.empty?

    IPAddr.new(allowed).include?(request_ip)
  rescue IPAddr::InvalidAddressError
    request_ip == allowed
  end

  def current_request_ip
    request.ip
  end

  def safe_status_code(response)
    if response.respond_to?(:code) && !response.code.to_s.strip.empty?
      response.code.to_s
    else
      'unknown'
    end
  end

  def safe_json_parse(body, context:)
    JSON.parse(body)
  rescue JSON::ParserError => e
    LOGGER.warn("[#{context}] JSON parse error: #{e.class}: #{e.message}")
    { 'raw' => body }
  end

  def language_label_for(query)
    return 'unknown' if query.to_s.strip.empty?

    query.to_s.ascii_only? ? 'latin' : 'non_latin'
  end

  def weather_api_key
    ENV['OPENWEATHER_API_KEY'].to_s.strip
  end

  def http_get_json(uri_string, phase:)
    uri = URI(uri_string)
    started_at = monotonic_now

    response = Net::HTTP.get_response(uri)
    status_code = safe_status_code(response)
    duration = monotonic_now - started_at

    WEATHER_API_REQUESTS_TOTAL.increment(
      labels: { phase: phase, status_code: status_code }
    )

    WEATHER_API_DURATION_SECONDS.observe(
      duration,
      labels: { phase: phase, status_code: status_code }
    )

    safe_json_parse(response.body.to_s, context: "openweather:#{phase}")
  rescue StandardError => e
    WEATHER_API_ERRORS_TOTAL.increment(
      labels: { phase: phase, error_class: e.class.name }
    )
    raise
  end

  def find_user_for_login(identifier)
    DB[:users].where(email: identifier).first ||
      DB[:users].where(username: identifier).first
  end

  def get_weather_for(city, country = nil)
    location_query =
      if country.to_s.strip.empty?
        city
      else
        "#{city},#{country}"
      end

    geocoding_url = "https://api.openweathermap.org/geo/1.0/direct?q=#{URI.encode_www_form_component(location_query)}&limit=1&appid=#{weather_api_key}"
    geocoding_data = http_get_json(geocoding_url, phase: 'geocoding')

    first_match = geocoding_data.is_a?(Array) ? geocoding_data.first : nil
    raise Sinatra::NotFound, 'City not found' unless first_match

    lat = first_match.fetch('lat')
    lon = first_match.fetch('lon')

    weather_url = "https://api.openweathermap.org/data/2.5/weather?lat=#{lat}&lon=#{lon}&appid=#{weather_api_key}&units=metric&lang=da"
    weather_data = http_get_json(weather_url, phase: 'weather')

    {
      'location' => first_match,
      'weather' => weather_data
    }
  end

  def json_request?
    request.path_info.start_with?('/api/') || request.media_type.to_s.include?('application/json')
  end
end

before do
  env['metrics.started_at'] = monotonic_now

  if session[:user_id] && !['/change-password', '/logout', '/api/logout', '/api/change-password'].include?(request.path_info)
    user = DB[:users].where(id: session[:user_id]).select(:password_reset_required).first
    redirect '/change-password' if user && user[:password_reset_required] == 1 && !request.path_info.start_with?('/api/')
  end
end

after do
  next if skip_http_metrics?(env)

  status_code = response.status.to_i.to_s
  duration = monotonic_now - env.fetch('metrics.started_at', monotonic_now)

  labels = {
    method: request.request_method,
    path: metrics_path_label(env),
    status_code: status_code
  }

  HTTP_REQUESTS_TOTAL.increment(labels: labels)
  HTTP_REQUEST_DURATION_SECONDS.observe(duration, labels: labels)
end

error do
  err = env['sinatra.error']
  path = metrics_path_label(env)

  unless request.path_info == '/metrics'
    HTTP_REQUEST_ERRORS_TOTAL.increment(
      labels: {
        method: request.request_method,
        path: path,
        error_class: err.class.name
      }
    )
  end

  LOGGER.error("#{err.class}: #{err.message}") if err

  if json_request?
    status 500
    json error: 'internal_server_error'
  else
    content_type 'text/plain'
    status 500
    'Internal Server Error'
  end
end

get '/health' do
  json status: 'ok'
end

get '/metrics' do
  monitoring_ip = ENV['MONITORING_IP'].to_s.strip
  monitoring_ip = '127.0.0.1' if monitoring_ip.empty?

  halt 403, 'Forbidden' unless allowed_ip?(current_request_ip, monitoring_ip)

  content_type 'text/plain; version=0.0.4; charset=utf-8'
  Prometheus::Client::Formats::Text.marshal(PROM_REGISTRY)
end

###############
# HTML ROUTES
###############

get '/' do
  query = params[:query]
  language = params[:language] || 'en'

  if query.nil?
    erb :home
  else
    started_at = monotonic_now
    dataset = DB[:pages]
    dataset = dataset.where(language: language)
    dataset = apply_search_filters(dataset, query, language) unless query.to_s.strip.empty?
    results = dataset.select(:title, :url, :language, :last_updated, :content).all
    hit = results.empty? ? 'miss' : 'hit'
    LOGGER.info("[SEARCH] query=#{query.to_s.strip.inspect} language=#{language.inspect} hit=#{hit} results=#{results.size}")
    duration = monotonic_now - started_at

    SEARCH_QUERIES_TOTAL.increment(labels: { language: language_label_for(query), hit: hit })
    SEARCH_DURATION_SECONDS.observe(duration, labels: { language: language_label_for(query), hit: hit })

    erb :search, locals: { search_results: results, query: query }
  end
end

get '/about' do
  erb :about
end

get '/login' do
  erb :login, locals: { error: nil }
end

post '/login' do
  payload = request_payload
  identifier = payload_value(payload, :email).to_s.strip
  identifier = payload_value(payload, :username).to_s.strip if identifier.empty?
  password = payload_value(payload, :password).to_s

  user = find_user_for_login(identifier)

  if user && password_matches?(user[:password], password)
    LOGIN_ATTEMPTS_TOTAL.increment(labels: { result: 'success' })
    session[:user_id] = user[:id]
    session[:username] = user[:username] if user[:username]

    if request.media_type.to_s.include?('application/json')
      status 200
      json message: 'login ok'
    else
      redirect '/'
    end
  else
    LOGIN_ATTEMPTS_TOTAL.increment(labels: { result: 'failure' })

    if request.media_type.to_s.include?('application/json')
      halt 401, json(error: 'Invalid credentials')
    else
      status 401
      erb :login, locals: { error: 'Invalid credentials' }
    end
  end
end

get '/register' do
  erb :register, locals: { error: nil }
end

post '/register' do
  payload = request_payload
  error = validate_registration_fields(payload)

  email = payload_value(payload, :email).to_s.strip
  username = payload_value(payload, :username).to_s.strip

  error = 'The username already exists' if error.nil? && !username.empty? && DB[:users].where(username: username).first
  error = 'The email already exists' if error.nil? && !email.empty? && DB[:users].where(email: email).first

  if error
    REGISTRATIONS_TOTAL.increment(labels: { result: 'failure' })

    if request.media_type.to_s.include?('application/json')
      halt 422, json(error: error)
    else
      status 422
      return erb :register, locals: { error: error }
    end
  end

  insert_data = {
    email: email,
    password: hash_password(payload['password'].to_s)
  }
  insert_data[:username] = username unless username.empty?

  user_id = DB[:users].insert(insert_data)

  REGISTRATIONS_TOTAL.increment(labels: { result: 'success' })
  session[:user_id] = user_id
  session[:username] = username unless username.empty?

  if request.media_type.to_s.include?('application/json')
    status 201
    json message: 'registered'
  else
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

  unless password_matches?(user[:password], params[:current_password].to_s)
    PASSWORD_CHANGES_TOTAL.increment(labels: { result: 'failure' })
    return erb :change_password, locals: { error: 'Current password is incorrect' }
  end

  if params[:new_password].to_s.length < 8
    PASSWORD_CHANGES_TOTAL.increment(labels: { result: 'failure' })
    return erb :change_password, locals: { error: 'New password must be at least 8 characters' }
  end

  if params[:new_password].to_s != params[:new_password2].to_s
    PASSWORD_CHANGES_TOTAL.increment(labels: { result: 'failure' })
    return erb :change_password, locals: { error: 'New passwords do not match' }
  end

  DB[:users].where(id: session[:user_id]).update(
    password: hash_password(params[:new_password].to_s),
    password_reset_required: 0
  )

  PASSWORD_CHANGES_TOTAL.increment(labels: { result: 'success' })
  redirect '/'
end

post '/logout' do
  session.delete(:user_id)
  session.delete(:username)
  session[:flash] = 'You were logged out'
  redirect '/'
end

get '/weather' do
  city = params.fetch(:city, 'København').to_s.strip
  country = params.fetch(:country, '').to_s.strip

  payload = get_weather_for(city, country)
  @loc = payload['location']
  @w = payload['weather']
  erb :weather
end

###############
# API ROUTES
###############

get '/api/docs' do
  spec_url = '/api/docs/openapi.yaml'
  erb :openapi, locals: { spec_url: spec_url }, layout: false
end

get '/api/docs/openapi.yaml' do
  content_type 'text/yaml'
  send_file File.join(settings.root, 'OpenAPI', 'OpenAPI.yaml')
end

get '/api/users' do
  content_type :json
  DB[:users].select(:id, :username, :email).all.to_json
end

get '/api/search' do
  query = params['query'].to_s.strip
  language = params['language'].to_s.strip
  language = 'en' if language.empty?

  started_at = monotonic_now

  dataset = DB[:pages]
  dataset = dataset.where(language: language) unless language.empty?
  dataset = apply_search_filters(dataset, query, language) unless query.empty?
  results = dataset.select(:title, :url, :language, :last_updated, :content).all
  hit = results.empty? ? 'miss' : 'hit'
  LOGGER.info("[SEARCH] query=#{query.inspect} language=#{language.inspect} hit=#{hit} results=#{results.size}")
  duration = monotonic_now - started_at

  SEARCH_QUERIES_TOTAL.increment(labels: { language: language_label_for(query), hit: hit })
  SEARCH_DURATION_SECONDS.observe(duration, labels: { language: language_label_for(query), hit: hit })

  json results: results
end

post '/api/login' do
  payload = request_payload
  identifier = payload_value(payload, :email).to_s.strip
  identifier = payload_value(payload, :username).to_s.strip if identifier.empty?
  password = payload_value(payload, :password).to_s

  user = find_user_for_login(identifier)

  if user && password_matches?(user[:password], password)
    LOGIN_ATTEMPTS_TOTAL.increment(labels: { result: 'success' })
    session[:user_id] = user[:id]
    session[:username] = user[:username] if user[:username]
    status 200
    json message: 'Login successful', username: user[:username]
  else
    LOGIN_ATTEMPTS_TOTAL.increment(labels: { result: 'failure' })
    halt 401, json(error: 'Invalid credentials')
  end
end

post '/api/register' do
  payload = request_payload
  error = validate_registration_fields(payload)

  email = payload_value(payload, :email).to_s.strip
  username = payload_value(payload, :username).to_s.strip

  error = 'The username already exists' if error.nil? && DB[:users].where(username: username).first
  error = 'The email already exists' if error.nil? && DB[:users].where(email: email).first

  if error
    REGISTRATIONS_TOTAL.increment(labels: { result: 'failure' })
    halt 400, json(error: error)
  end

  insert_data = {
    email: email,
    password: hash_password(payload['password'].to_s)
  }
  insert_data[:username] = username unless username.empty?

  user_id = DB[:users].insert(insert_data)

  REGISTRATIONS_TOTAL.increment(labels: { result: 'success' })
  session[:user_id] = user_id
  session[:username] = username unless username.empty?

  status 200
  json message: 'Registration successful', username: username
end

post '/api/logout' do
  session.delete(:user_id)
  session.delete(:username)
  json message: 'logout ok'
end

post '/api/change-password' do
  halt 401, json(error: 'not_authenticated') unless session[:user_id]

  payload = request_payload
  old_password = payload['old_password'].to_s
  old_password = payload['current_password'].to_s if old_password.empty?
  new_password = payload['new_password'].to_s

  user = DB[:users].where(id: session[:user_id]).first

  unless user && password_matches?(user[:password], old_password)
    PASSWORD_CHANGES_TOTAL.increment(labels: { result: 'failure' })
    halt 401, json(error: 'invalid_credentials')
  end

  if new_password.length < 8
    PASSWORD_CHANGES_TOTAL.increment(labels: { result: 'failure' })
    halt 422, json(error: 'new_password_too_short')
  end

  DB[:users].where(id: session[:user_id]).update(
    password: hash_password(new_password),
    password_reset_required: 0
  )

  PASSWORD_CHANGES_TOTAL.increment(labels: { result: 'success' })
  json message: 'password changed'
end

get '/api/weather' do
  city = params['city'].to_s.strip
  country = params['country'].to_s.strip

  halt 422, json(error: 'city is required') if city.empty?

  payload = get_weather_for(city, country)
  json payload
end
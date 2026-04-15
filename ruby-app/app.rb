# frozen_string_literal: true

require 'sinatra'
require 'sequel'
require 'json'
require 'bcrypt'
require 'net/http'
require 'uri'
require 'dotenv/load'

enable :sessions

set :protection, except: :host_authorization

DB = Sequel.connect(ENV.fetch('DATABASE_URL'))

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
  if session[:user_id] && !['/change-password', '/logout', '/api/logout'].include?(request.path_info)
    user = DB[:users].where(id: session[:user_id]).select(:password_reset_required).first
    redirect '/change-password' if user && user[:password_reset_required] == 1
  end
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

###############
# DATABASE
###############

def get_user_id(username)
  user = DB[:users].where(username: username).select(:id).first
  user ? user[:id] : nil
end

###############
# SHARED LOGIC
###############

def search_pages_query(language, query)
  return [] if query.to_s.strip.empty?

  term = query.to_s.strip.split(/\s+/).map { |w| "#{w}:*" }.join(' & ')
  DB[:pages]
    .where(language: language)
    .where(Sequel.lit("search_vector @@ to_tsquery('english', ?)", term))
    .order(Sequel.lit("ts_rank(search_vector, to_tsquery('english', ?)) DESC", term))
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
    erb :login, locals: { error: error }
  else
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
    redirect '/'
  end
end

get '/change-password' do
  redirect '/login' unless session[:user_id]
  erb :change_password, locals: { error: nil }
end

post '/change-password' do
  redirect '/login' unless session[:user_id]

  db = connect_db
  user = db.execute('SELECT * FROM users WHERE id = ?', [session[:user_id]]).first
  halt 403 unless user

  unless password_matches?(user[3], params[:current_password])
    db.close
    return erb :change_password, locals: { error: 'Current password is incorrect' }
  end

  if params[:new_password].to_s.strip.empty?
    db.close
    return erb :change_password, locals: { error: 'New password cannot be empty' }
  end

  if params[:new_password] != params[:new_password2]
    db.close
    return erb :change_password, locals: { error: 'New passwords do not match' }
  end

  hashed = hash_password(params[:new_password])
  db.execute('UPDATE users SET password = ?, password_reset_required = 0 WHERE id = ?',
             [hashed, session[:user_id]])
  db.close

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
  { message: 'Search endpoint hit', results: search_results }.to_json
end

post '/api/login' do
  content_type :json
  user, error = authenticate_user(params[:username], params[:password])

  halt 401, { error: error }.to_json if error

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
  location_query = country.strip.empty? ? city : "#{city},#{country}"

  status, location = resolve_location(location_query, api_key)
  return [status, location] unless status == 200

  weather_status, weather_data = fetch_weather(location['lat'], location['lon'], api_key)
  return [weather_status, { 'error' => 'weather fetch failed', 'details' => weather_data }] unless weather_status == 200

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

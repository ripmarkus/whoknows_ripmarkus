# frozen_string_literal: true

require 'sinatra'
require 'sqlite3'
require 'json'
require 'bcrypt'
require 'net/http'
require 'uri'
require 'dotenv/load'

enable :sessions

DATABASE_PATH = File.join(__dir__, 'whoknows.db')

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

###############
# VIEWS
###############

get '/' do
  query    = params[:query]
  language = params[:language] || 'en'
  db = connect_db
  search_results = query ? search_pages_query(db, language, query) : []
  db.close
  erb :search, locals: { search_results: search_results, query: query }
end

get '/about' do
  erb :about
end

get '/login' do
  erb :login
end

get '/register' do
  erb :register
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
def connect_db(init_mode: false)
  check_db_exists unless init_mode
  SQLite3::Database.new(DATABASE_PATH)
end

def check_db_exists
  return if File.exist?(DATABASE_PATH)

  puts 'Database not found'
  exit(1)
end

def init_db
  db = connect_db(init_mode: true)
  schema = File.read('../schema.sql')
  db.execute_batch(schema)
  db.close
  puts "Initialized the database: #{DATABASE_PATH}"
end

def query_db(db, query, args = [], one: false)
  results = []
  db.execute(query, args) do |row, fields|
    results << fields.map { |col| [col[0], row[fields.index(col)]] }.to_h
  end
  one ? (results.first || nil) : results
end

def get_user_id(db, username)
  row = db.execute('SELECT id FROM users WHERE username = ?', username).first
  row ? row[0] : nil
end

###############
# API ENDPOINTS
###############

get '/api/users' do
  content_type :json
  db = connect_db
  users = []

  db.execute('SELECT id, username, email FROM users') do |row|
    users << { id: row[0], username: row[1], email: row[2] }
  end

  db.close
  users.to_json
end

# changed this to accept parameters, so it can be used other places
def search_pages_query(db, language, query)
  sql = 'SELECT * FROM pages WHERE language = ? AND content LIKE ?'
  pages = []

  db.execute(sql, [language, "%#{query}%"]) do |row|
    title, url, language, last_updated, content = row
    pages << { title: title, url: url, language: language, last_updated: last_updated, content: content }
  end

  pages
end

get '/api/search' do
  content_type :json
  query    = params[:query]
  language = params[:language] || 'en'
  db = connect_db
  search_results = query ? search_pages_query(db, language, query) : []
  db.close
  { message: 'Search endpoint hit', results: search_results }.to_json
end

post '/api/login' do
  db = connect_db
  error = nil
  user = db.execute('SELECT * FROM users WHERE username = ?', [params[:username]]).first

  if user.nil?
    error = 'Invalid username'
  elsif !password_matches?(user[3], params[:password])
    error = 'Invalid password'
  else
    session[:user_id] = user[0]
    session[:username] = user[1]
    redirect '/'
  end

  db.close
  erb :login, locals: { error: error } if error
end

def validate_registration_fields(params)
  return 'You have to enter a username' if params[:username].nil? || params[:username].empty?
  return 'Valid email address needed' if params[:email].nil? || !params[:email].include?('@')
  return 'You have to enter a password' if params[:password].nil?
  'The two passwords do not match' if params[:password] != params[:password2]
end

def validate_registration(db, params)
  error = validate_registration_fields(params)
  return error if error
  'The username already exists' if get_user_id(db, params[:username])
end
post '/api/register' do
  redirect '/' if session[:user_id]

  db = connect_db
  error = validate_registration(db, params)

  if error
    db.close
    erb :register, locals: { error: error } # re-render form with error
  else
    hashed_pw = hash_password(params[:password])
    db.execute('INSERT INTO users (username, email, password) VALUES (?, ?, ?)',
               [params[:username], params[:email], hashed_pw])
    session[:user_id] = get_user_id(db, params[:username]) # log them in
    session[:username] = params[:username]
    db.close
    redirect '/'
  end
end

post '/api/logout' do
  session[:flash] = 'You were logged out'
  session.delete(:user_id)
  redirect '/'
end

###############
# SECURITY
###############

# TODO: Use in the register api route
def hash_password(password)
  BCrypt::Password.create(password)
end

# TODO: Use in the login api route
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

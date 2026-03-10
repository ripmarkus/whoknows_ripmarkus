require 'sinatra'
require 'sqlite3'
require 'json'
require 'bcrypt'
require 'net/http'
require 'uri'
require 'dotenv/load'


enable :sessions

DATABASE_PATH = File.join(__dir__, 'whoknows.db')

#XSS (Cross-site scripting) sanitizes html output to prevent malicious scripts from being executed in the browser
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
    parsed = { "raw" => body }
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
  spec_url = "/api-docs/openapi.yaml"
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
  unless File.exist?(DATABASE_PATH)
    puts "Database not found"
    exit(1)
  end
end

def init_db
  db = connect_db(init_mode: true)
  schema = File.read('../schema.sql')
  db.execute_batch(schema)
  db.close
  puts "Initialized the database: #{DATABASE_PATH}"
###############
end

def get_db
  SQLite3::Database.new 'whoknows.db'
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
  
  db.execute("SELECT id, username, email FROM users") do |row|
    users << { id: row[0], username: row[1], email: row[2] }
  end

  db.close
  users.to_json
end

  # changed this to accept parameters, so it can be used other places
def search_pages_query(db, language, query)
  sql = "SELECT * FROM pages WHERE language = ? AND content LIKE ?"
  pages = []

  db.execute(sql, [language, "%#{query}%"]) do |row|
    id, title, lang, content = row
    pages << { id: id, title: title, language: lang, content: content }
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
  { message: "Search endpoint hit", results: search_results }.to_json
end

post '/api/login' do
  db = connect_db
  error = nil
  user = db.execute("SELECT * FROM users WHERE username = ?", [params[:username]]).first

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

post '/api/register' do
  redirect '/' if session[:user_id]
  error = nil
  db = connect_db

  if params[:username].nil? || params[:username].empty?
    error = "You have to enter a username"
  elsif params[:email].nil? || !params[:email].include?('@')
    error = "Valid email address needed"
  elsif params[:password].nil?
    error = "You have to enter a password"
  elsif params[:password] != params[:password2]
    error = "The two passwords do not match"
  elsif get_user_id(db, params[:username])
    error = "The username already exists"
  end

  if error
    db.close
    erb :register, locals: { error: error }  # re-render form with error
  else
    hashed_pw = hash_password(params[:password])
    db.execute("INSERT INTO users (username, email, password) VALUES (?, ?, ?)",
               [params[:username], params[:email], hashed_pw])
    session[:user_id] = get_user_id(db, params[:username])  # log them in
    session[:username] = params[:username]
    db.close
    redirect '/'
  end
end

post "/api/logout" do
  session[:flash] = "You were logged out"
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

# Weather function - gets lat/lon for city/country and then gets weather for that location
def get_weather_for(city:, country:, api_key:)
  location_query = country.strip.empty? ? city : "#{city},#{country}"

  geocoding_uri = URI("https://api.openweathermap.org/geo/1.0/direct?q=#{URI.encode_www_form_component(location_query)}&limit=1&appid=#{api_key}")
  geocoding_status, geocoding_result = http_get_json(geocoding_uri)
  return [geocoding_status, { "error" => "geocoding failed", "details" => geocoding_result }] unless geocoding_status == 200
  return [404, { "error" => "no location found", "query" => location_query }] unless geocoding_result.is_a?(Array) && geocoding_result.any?

  location = geocoding_result.first
  latitude, longitude = location["lat"], location["lon"]
  return [502, { "error" => "no lat/lon", "location" => location }] if latitude.nil? || longitude.nil?

  weather_uri = URI("https://api.openweathermap.org/data/2.5/weather?lat=#{latitude}&lon=#{longitude}&units=metric&lang=da&appid=#{api_key}")
  weather_status, weather_data = http_get_json(weather_uri)
  return [weather_status, { "error" => "weather fetch failed", "details" => weather_data }] unless weather_status == 200

  [200, { "location" => location, "weather" => weather_data }]
end

# Shows the weather page for a given city and country, using the OpenWeather API, with error handling
# Example: /weather?city=København&country=DK
get "/weather" do
  api_key = ENV["OPENWEATHER_API_KEY"].to_s.strip
  halt 500, "Missing OPENWEATHER_API_KEY" if api_key.empty?

  city    = params.fetch(:city, "København").to_s.strip
  country = params.fetch(:country, "").to_s.strip

  status, payload = get_weather_for(city: city, country: country, api_key: api_key)
  halt status, payload.to_json unless status == 200

  @loc = payload["location"]
  @w   = payload["weather"]
  erb :weather
end

# Example: /api/weather?city=København&country=DK
# Gets weather data for a given city within a country, using the OpenWeather API, with error handling and JSON response
get "/api/weather" do
  content_type :json
  api_key = ENV["OPENWEATHER_API_KEY"].to_s.strip
  halt 500, { error: "Missing OPENWEATHER_API_KEY" }.to_json if api_key.empty?

  city    = params.fetch(:city, "København").to_s.strip
  country = params.fetch(:country, "").to_s.strip

  status, payload = get_weather_for(city: city, country: country, api_key: api_key)
  halt status, payload.to_json unless status == 200

  payload.to_json
end
require 'sinatra'
require 'sqlite3'
require 'json'
require 'bcrypt'

enable :sessions

#Shows the search page
get '/' do
  query    = params[:query]
  language = params[:language] || 'en'
  search_results = query ? search_pages_query(get_db, language, query) : []
  erb :search, locals: { search_results: search_results, query: query }
end


# VIEWS
get '/about' do
    erb :about
end

get '/login' do
    erb :login
end

get '/register' do
    erb :register
end

# DATABASE
def get_db
    SQLite3::Database.new 'whoknows.db'
end

def get_user_id_query(db, username)
  row = db.execute('SELECT id FROM users WHERE username = ?', username).first
  row ? row[0] : nil
  end

# ENDPOINTS   
get '/api/users' do
    content_type :json
    db = get_db
    users = []
  
  db.execute("SELECT id, username, email FROM users") do |row|
    users << { id: row[0], username: row[1], email: row[2] }
  end
  
  db.close
  users.to_json
end

get '/api/search' do
  content_type :json
  query    = params[:query]
  language = params[:language] || 'en'
  search_results = query ? search_pages_query(get_db, language, query) : []
  { message: "Search endpoint hit", results: search_results }.to_json
end

post '/api/login' do
  db = get_db
  error = nil
  user = db.execute("SELECT * FROM users WHERE username = ?", [params[:username]]).first

  if user.nil?
    error = 'Invalid username'
  elsif !password_matches?(user[3], params[:password])
    error = 'Invalid password'
  else
    session[:user_id] = user[0]
    redirect '/'
  end

  db.close
  erb :login, locals: { error: error } if error
end

post '/api/register' do
  content_type :json
  redirect '/search' if session[:user_id]
  error = nil

  if params[:username].nil? || params[:username].empty?
    error = "You have to enter a username"
  elsif params[:email].nil? || !params[:email].include?('@')
    error = "Valid email address needed"
  elsif params[:password].nil?
    error = "You have to enter a password"
  elsif params[:password] != params[:password2]
    error = "The two passwords do not match"
  elsif get_user_id_query(get_db, params[:username])
    error = "The username already exists"
  end

  if error
    { message: error }.to_json
  else
    db = get_db
    hashed_pw = hash_password(params[:password])
    db.execute("INSERT INTO users (username, email, password) VALUES (?, ?, ?)",
               [params[:username], params[:email], hashed_pw])
    { message: "You were successfully registered and can login now" }.to_json
  end
end


get "/api/logout" do
    content_type :json

    {
      message: "Logout endpoint hit"
    }.to_json
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
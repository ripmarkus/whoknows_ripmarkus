require 'sinatra'
require 'sqlite3'
require 'json'
require 'bcrypt'

#Shows the search page
get '/' do
  query    = params[:query]
  language = params[:language] || 'en'
  search_results = query ? search_pages_query(db, language, query) : []
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
  search_results = query ? search_pages_query(db, language, query) : []
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

    {
      message: "Register endpoint hit"
    }.to_json
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
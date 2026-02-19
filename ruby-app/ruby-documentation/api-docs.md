# API Documentation

In the provided python code, we are provided with the following API endpoints:

| Method | Route         | Description |
|--------|---------------|-------------|
| GET    | /api/search   |Search endpoint, requires the query param `q` and an optional `language` code. Returns a  list of objects.       |
| GET    | /api/weather  |Returns current weather as JSON        |
| GET    | /api/logout   |Logs the current user out             |
| POST   | /api/register |Registers a new user, fields needed: `username`, `email`, `password` and `password2`             |
| POST   | /api/login    | Logs the user in, fields needed: `username`, `password`             |


## Sinatra Route Handling

In Sinatra, we can write an endpoint like this:

First, we write the HTTP methods we want, and then the url string.

```ruby
get '/some-endpoint'
```
Then we set the content type to JSON.

```ruby
content_type :json
```
If we expect a param

```ruby
some_param = params[:the_param]
if(some_logic){
    // logic here
}
```

Lastly, we return the logic

```ruby
    { message: "Some endpoint has been hit!", results: some_logic}.to.json
end
```

## These are the endpoints we have finished so far:

### /api/search

```ruby
get '/api/search' do
  content_type :json
  query    = params[:query]
  language = params[:language] || 'en'
  search_results = query ? search_pages_query(get_db, language, query) : []
  { message: "Search endpoint hit", results: search_results }.to_json
end
```

### /api/register

```ruby
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
```

## These are the ones we still need the logic for:

### /api/logout

```ruby
get "/api/logout" do
    content_type :json

    {
      message: "Logout endpoint hit"
    }.to_json
end
```
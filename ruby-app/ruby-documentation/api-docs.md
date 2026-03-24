# API Documentation

In the legacy python code, we are provided with the following API endpoints:

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

## All Endpoints

We changed the API endpoints `/api/login`, `/api/register` and `/api/logout` so that they will return JSON when the client request has `Content-Type: application/json` and HTML redirects otherwise.

It defeated the purpose of having API endpoints when all they did was return HTML and not data.

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

Several things that could be better here:

1. Too much nested code.
2. We should move the db.execute into a separate method, also for readability and maintainability.
3. No password security check (minimum length, special characters)
4. Email validation is still weak

```ruby
post '/api/register' do
  if session[:user_id]
    if json_request?
      content_type :json
      halt 400, { error: 'Already logged in' }.to_json
    else
      redirect '/'
    end
  end

  db = connect_db
  error = validate_registration(db, params)

  if error
    db.close
    if json_request?
      content_type :json
      halt 400, { error: error }.to_json
    else
      erb :register, locals: { error: error }
    end
  else
    hashed_pw = hash_password(params[:password])
    db.execute('INSERT INTO users (username, email, password) VALUES (?, ?, ?)',
               [params[:username], params[:email], hashed_pw])
    session[:user_id] = get_user_id(db, params[:username])
    session[:username] = params[:username]
    db.close
    if json_request?
      content_type :json
      { message: 'Registration successful', username: params[:username] }.to_json
    else
      redirect '/'
    end
  end
end
```

### /api/logout

```ruby
post '/api/logout' do
  session.delete(:user_id)
  if json_request?
    content_type :json
    { message: 'Logout successful' }.to_json
  else
    session[:flash] = 'You were logged out'
    redirect '/'
  end
end
```
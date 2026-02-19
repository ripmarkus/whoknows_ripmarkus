# API Documentation

In the provided python code, we are provided with the following API endpoints:

| Method | Route         | Description |
|--------|---------------|-------------|
| GET    | /api/search   |Search endpoint, requires the query param `q` and an optional `language` code. Returns a  list of objects.       |
| GET    | /api/weather  |Returns current weather as JSON        |
| GET    | /api/logout   |Logs the current user out             |
| POST   | /api/register |Registers a new user, fields needed: `username`, `email`, `password` and `password2`             |
| POST   | /api/login    | Logs the user in, fields needed: `username`, `password`             |


## These are the endpoints we have finished so far:

```ruby
get '/api/search' do
  content_type :json
  query    = params[:query]
  language = params[:language] || 'en'
  search_results = query ? search_pages_query(get_db, language, query) : []
  { message: "Search endpoint hit", results: search_results }.to_json
end
```

```ruby

```
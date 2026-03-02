# Database

This documentation looks at the new methods so that we as a team can understand the methods better, and also understand where the legacy code failed - especially with SQL Injection vulnerabilites.

## Connection & Lifecycle

`connect_db` opens a new SQLite connection. It checks that the database file exists before connecting, unless called in `init_mode` (used only during setup).

```ruby
def connect_db(init_mode: false)
  check_db_exists unless init_mode
  SQLite3::Database.new(DATABASE_PATH)
end
```

Previously (Python/Flask), the connection was managed globally via `g.db` in `before_request` / `after_request`, shared across all queries in a request. It is now opened and closed explicitly per route in Ruby/Sinatra, keeping the connection lifetime tied to the request.

```ruby
get '/api/search' do
  db = get_db
  search_results = search_pages_query(db, language, query)
  db.close
  search_results.to_json
end
```

## Querying

`query_db` is a general-purpose helper that executes a parameterized query and returns results as an array of hashes. Pass `one: true` to return only the first result.

```ruby
# Returns all matching rows as hashes
query_db(db, "SELECT * FROM users WHERE email = ?", [email])

# Returns only the first match
query_db(db, "SELECT * FROM users WHERE username = ?", [username], one: true)
```

`get_user_id` looks up a user's ID by username.

```ruby
def get_user_id(db, username)
  row = db.execute('SELECT id FROM users WHERE username = ?', username).first
  row ? row[0] : nil
end
```

## SQL Injection Prevention

The Python and Ruby versions previously held queries with string formatting, allowing attackers to inject SQL through the `query` or `language` parameters.

```python
# Before (Python) - vulnerable to SQL injection
query_db("SELECT * FROM pages WHERE language = '%s' AND content LIKE '%%%s%%'" % (language, q))
```

```ruby
# After (Ruby) - parameterized query, user input is never interpreted as SQL
sql = "SELECT * FROM pages WHERE language = ? AND content LIKE ?"
db.execute(sql, [language, "%#{query}%"])
```

SQLite3's `?` placeholders ensure all input is treated as data, not SQL, thus preventing an SQL Injection attack.
# SQLite to PostgreSQL Migration

## What changed

### Database
- Replaced SQLite3 (`sqlite3` gem) with PostgreSQL (`pg` + `sequel` gems)
- Connection is now configured via the `DATABASE_URL` environment variable
- Schema is managed through versioned migration files in `db/migrations/`
- Run migrations with: `ruby db/migrate.rb` (safe to re-run — Sequel tracks applied migrations)

### Search
- Replaced SQLite `LIKE` query with Postgres full-text search (`tsvector`/`tsquery`)
- Results are ranked by relevance using `ts_rank`
- Prefix matching supported — "jav" matches "java", "javascript"
- Search covers both `title` and `content` fields

### Indexes
- Composite index on `pages(language, title)` for search queries
- `users.username` and `users.email` are indexed via their `UNIQUE` constraints

### Files removed
- `init_db.rb` — replaced by `db/migrations/001_create_users.rb` and `002_create_pages.rb`
- `init_pages.rb` — no longer needed; seed data lives in the migration

### Files added
- `db/migrations/001_create_users.rb` — users table schema + admin seed
- `db/migrations/002_create_pages.rb` — pages table schema
- `db/migrations/003_add_indexes.rb` — composite index on pages
- `db/migrations/004_add_fts.rb` — tsvector column, GIN index, update trigger
- `db/migrate.rb` — migration runner
- `docker-compose.yml` — postgres + app services

## Running locally

```bash
docker compose up --build
```

The app runs migrations automatically before starting.

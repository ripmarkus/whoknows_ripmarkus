# SQLite to PostgreSQL Migration

## Database

The `sqlite3` gem was replaced with `pg` and `sequel`. The app now connects to PostgreSQL using a `DATABASE_URL` environment variable. Schema is managed through versioned migration files in `db/migrations/`, run via `ruby db/migrate.rb`. Sequel tracks which migrations have been applied, so it is safe to re-run on every deploy.

## Search

The old `LIKE` query on `pages.title` was replaced with Postgres full-text search using `tsvector` and `tsquery`. Results are ranked by relevance with `ts_rank` and the search covers both `title` and `content`. Prefix matching is enabled, so a query like "jav" will match "java" and "javascript".

## Indexes

A composite index on `pages(language, title)` was added to speed up search queries. The `users.username` and `users.email` columns are already indexed through their `UNIQUE` constraints.

## Files removed

`init_db.rb` and `init_pages.rb` were removed. Their responsibilities are now handled by the Sequel migration files in `db/migrations/`.

## Running locally

```bash
docker compose up --build
```

Migrations run automatically before the app starts.

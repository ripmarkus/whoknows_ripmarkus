# SQLite to PostgreSQL Migration

## Why PostgreSQL?

PostgreSQL was chosen as an alternative to SQLite, because it:

1. Works better with Docker, since it's not a file on a disk.
2. Has native full text search with tsvector and tsquery, instead of FTS5 in SQLite that has to be defined seperately.
3. Handles concurrent writes, whereas SQLite locks the entire file on writes.

## Why not another DB type?

| Database | Reason |
|---|---|
| SQLite | File-based, locks on writes, not suited for Docker or concurrent production traffic |
| MySQL | Looser SQL standards compliance, weaker full-text search, no meaningful advantage over PostgreSQL here |
| MongoDB | Document store — poor fit for relational data like users and pages with foreign key constraints |
| Redis | In-memory key-value store, not a relational database — suited for caching, not primary storage |
| Cassandra | Designed for distributed, high-volume write workloads — far more complexity than this app requires |
| Elasticsearch | A search engine, not a general-purpose database — overkill when PostgreSQL full-text search covers the use case |

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

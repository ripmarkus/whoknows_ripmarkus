# Search

Search logic helpers, included via `SearchHelpers`.

- `apply_search_filters` — applies full-text search (Postgres) or LIKE fallback (SQLite) to a Sequel dataset, with rank ordering
- `language_label_for` — classifies a query string as `latin`, `non_latin`, or `unknown` for Prometheus labels

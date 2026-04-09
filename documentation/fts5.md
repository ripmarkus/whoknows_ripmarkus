# SQLite FTS5

## What changed
Replaced the `LIKE` operator with FTS5 (Full Text Search 5) for page searches.

## How it works
- A virtual table `pages_fts` mirrors the `pages` table
- Triggers on `pages` keep `pages_fts` in sync (insert, update, delete)
- Search queries use `MATCH` instead of `LIKE` and results are ranked by relevance

## LIKE vs FTS5

| | LIKE | FTS5 |
|---|------|------|
| Speed | Slow on large tables (full scan) | Fast (inverted index) |
| Relevance ranking | No | Yes (built-in `rank`) |
| Setup | None | Requires virtual table + triggers |
| Partial matches | Yes (`%word%`) | No (matches whole tokens) |
| Storage | No extra | Extra index table |

## SQLite limitations
- No concurrent writes (single-writer lock)
- No built-in replication
- Not suitable for high-traffic multi-server setups
- FTS5 may not be enabled in all SQLite builds (needs compile-time flag)

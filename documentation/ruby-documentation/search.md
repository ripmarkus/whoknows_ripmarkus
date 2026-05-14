# Search Indexing

## Overview

The search index is populated by a web crawler that scrapes curated pages and inserts them into the `pages` table via a protected API endpoint. The existing full-text search infrastructure (PostgreSQL FTS, `tsvector` column, GIN index) handles query execution.

---

## Ingest endpoint

`POST /api/pages` accepts a batch of page objects and upserts them into the database.

**Authentication:** `X-Crawler-Secret` header must match the `CRAWLER_SECRET` environment variable.

**Accepted payload shapes** - either a top-level array or a wrapped object:

```json
[
  {
    "title": "Docker",
    "url": "https://en.wikipedia.org/wiki/Docker_(software)",
    "content": "Docker is a set of platform as a service...",
    "language": "en"
  }
]
```

```json
{
  "pages": [
    { "title": "Docker", "url": "https://...", "content": "...", "language": "en" }
  ]
}
```

**Response:**
```json
{ "inserted": 1 }
```

Existing rows are updated by URL (upsert). Language must be `en` or `da`; anything else defaults to `en`. Entries missing `title`, `url`, or `content` are silently skipped and not counted.

---

## Crawler script

Location: `scraper/scraper.rb`

Scrapes the URLs listed in `scraper/targets.txt`, extracts title and body text with Nokogiri, and POSTs the results to `/api/pages`.

### Running locally

```bash
# from repo root
CRAWLER_SECRET=your-secret API_URL=http://localhost:4567 ruby scraper/scraper.rb
```

### Adding targets

Edit `scraper/targets.txt` - one URL per line. Lines starting with `#` are comments.

### Required env vars

| Variable | Description |
|---|---|
| `CRAWLER_SECRET` | Shared secret matching the app's `CRAWLER_SECRET` env var |
| `API_URL` | Base URL of the app (default: `http://localhost:4567`) |

---

## Scheduling strategy

### Decision: GitHub Actions cron schedule

The crawler runs weekly via a GitHub Actions scheduled workflow (`.github/workflows/crawler.yaml`), every Sunday at 03:00 UTC. It can also be triggered manually via `workflow_dispatch`.

### Tradeoffs

| Option | Pros | Cons |
|---|---|---|
| Manual script | Zero setup, full control | Requires human to run it |
| GitHub Actions cron | Free, repo-integrated, no extra infra, auditable run history | Scheduled workflows are **automatically disabled after 60 days of repo inactivity** in public repos; jobs may be dropped under high load - schedule at odd hours to mitigate |
| Serverless (Lambda/Cloud Run) | Always-on, scales infinitely, event-driven | Requires cloud account, extra infra to maintain, cost at scale |

GitHub Actions was chosen because it requires no external infrastructure, runs are logged and auditable in the repo, and the crawl volume is small enough that weekly scheduling is sufficient. Serverless would be the right upgrade path if the crawler needed to run hourly or respond to events.

### Required GitHub secrets

| Secret | Description |
|---|---|
| `CRAWLER_SECRET` | Must match the app's `CRAWLER_SECRET` env var |
| `API_URL` | Production URL of the app |

# Search Logging

Search queries are logged to `logs/app.log` using Ruby's built-in `Logger`. This gives insight into what users are searching for, which informs what content to scrape and index.

## Log format

Each search — from both the HTML route (`GET /`) and the API route (`GET /api/search`) — produces a line like:

```
I, [2026-04-28T12:00:00] INFO -- : [SEARCH] query="docker" language="en" hit="hit" results=4
```

| Field | Description |
|-------|-------------|
| `query` | The raw search term entered by the user |
| `language` | The language filter used (`en` or `da`) |
| `hit` | Whether any results were returned (`hit` or `miss`) |
| `results` | Number of results returned |

## Where logs are stored

Logs are written to `logs/app.log` inside the container, mounted to `ruby-app/logs/` on the host via Docker volume:

```yaml
volumes:
  - ./logs:/app/logs
```

## Tailing logs in production

```bash
tail -f logs/app.log | grep '\[SEARCH\]'
```

## How this informs scraping

The logged queries reveal what users actually search for. Those terms are used to decide which topics to scrape — see the scraper in `ruby-app/scraper/scraper.rb`.

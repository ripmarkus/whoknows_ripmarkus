# The Big Refactor

## What we did

We modularized `app.rb`, which had grown to 688 lines mixing concerns: Prometheus setup, authentication logic, search helpers, weather helpers, and all routes in one file.

---

## Step 1: Extracted logic into focused modules

Each concern got its own directory with a `.rb` file and a `README.md`.

| Directory | Module | Responsibility |
|---|---|---|
| `helpers/` | `AppHelpers` | General helpers: payload parsing, JSON response, clock, request type |
| `metrics/` | `MetricsHelpers` | Prometheus counters, histograms, path labelling, metrics skipping |
| `auth/` | `AuthHelpers` | Password hashing, login lookup, registration validation, IP allowlist |
| `search/` | `SearchHelpers` | Full-text search filters (Postgres + SQLite fallback), language labelling |
| `weather/` | `WeatherHelpers` | OpenWeatherMap geocoding, HTTP fetch, JSON parsing |

All modules are included into the Sinatra app via `helpers do; include ModuleName; end` in `app.rb`.

---

## Step 2: Moved routes into a routes folder

Two files under `routes/` replaced the inline route definitions:

- `routes/html_routes.rb` — browser-facing routes: `/`, `/login`, `/register`, `/change-password`, `/logout`, `/weather`, `/about`
- `routes/api_routes.rb` — machine-facing routes: `/health`, `/metrics`, and all `/api/*` endpoints

---

## Step 3: What app.rb looks like now

`app.rb` is now 97 lines and only contains:

- Gem requires
- `configure do` block (sessions, logger, database, Prometheus registry)
- Module requires
- `helpers do` block with includes
- `before`, `after`, and `error` hooks
- `require_relative` calls for the route files

---

## Step 4: Fixed a Docker permissions bug

The `compose.yaml` bind-mounts `./logs` into the container at `/app/logs`. The directory did not exist on the host, and a prior container run had created it as root, making it unwritable by `appuser`. We fixed the Dockerfile to pre-create the directory and then updated local permissions to unblock the container startup.

---

## Commit breakdown

Every file was committed individually, one commit per file created and one final commit per change to `app.rb`.

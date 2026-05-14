# CI/CD

Our GitHub Actions setup is split by responsibility. CI validates the Ruby app, CD deploys the production container, documentation deploys the MkDocs site, and RuboCop PR review gives readable feedback directly on pull requests.

This keeps the pipeline close to our GitHub Flow process: changes go through a PR, CI gives feedback before merge, and a successful merge to `main` can move into deployment.

## CI

The main CI workflow is `.github/workflows/CI.yaml`, named `Ruby CI`.

It runs on:

- pushes to `main`
- pull requests targeting `main`
- manual workflow dispatch

The workflow is structured as:

| Job | Purpose | Runs in parallel? |
|---|---|---|
| `test` | Runs RSpec against a real PostgreSQL service container | Yes |
| `lint` | Runs RuboCop as a blocking quality check | Yes |
| `docker_build` | Builds the Docker image and starts it with Docker Compose for a health check | No, waits for `test` and `lint` |
| `docker_push` | Pushes the image to GitHub Container Registry | No, waits for `docker_build` and skips PRs |

The `test` job starts `postgres:16-alpine` as a service container and sets `DATABASE_URL` to `postgres://whoknows:secret@localhost/whoknows_test`. This matches the PostgreSQL migration work described in [Postgres Migrations](../database/postgres-migration.md), and means tests catch database behavior that SQLite would hide.

The `lint` job runs in parallel with the tests because it does not need the database. This gives faster feedback without weakening the gate: Docker build only starts after both tests and lint pass.

The `docker_build` job builds the app image from `ruby-app/Dockerfile`, starts the Compose stack from `ruby-app/compose.yaml`, and checks `http://localhost:8080/`. That health check is our CI smoke test, which is why we have not added a separate browser smoke test in [Testing Overview](../testing/testing.md).

The `docker_push` job only runs outside pull requests. It logs into GHCR using `GITHUB_TOKEN`, builds the image from the `ruby-app` context, and publishes it under `ghcr.io/<repository-owner>/whoknows_ripmarkus`.

## RuboCop PR Review

`.github/workflows/rubocop.yaml` is separate from the blocking CI lint job.

Its job is not to decide whether the PR can merge. Its job is to generate a Markdown RuboCop report and keep a single PR comment updated with the latest result. This makes code quality feedback visible during review without duplicating comments on every run.

The workflow runs on pull requests when Ruby app code, the Gemfile, the lockfile, or `.rubocop.yml` changes.

## CD

The deployment workflow is `.github/workflows/CD.yaml`, named `Deployment`.

It runs when:

- a team member starts it manually with `workflow_dispatch`
- `Ruby CI` completes successfully on `main`

CD is intentionally kept in a separate workflow because it needs production secrets and should only run after the app has passed CI. It also has deployment concurrency enabled, so only one production deployment runs at a time.

### Required Secrets

The deployment workflow expects these GitHub secrets:

| Secret | Purpose |
|---|---|
| `SSH_KEY` | Private key used to SSH into the production server |
| `SERVER_USER` | SSH username |
| `SERVER_IP` | SSH host/IP |
| `GHCR_USERNAME` | Username used for GHCR login on the server |
| `GHCR_TOKEN` | Token used for GHCR image pulls on the server |

### Deployment Steps

The workflow connects to the server over SSH and runs the deployment from:

```bash
/opt/docker/devops/whoknows_ripmarkus/ruby-app
```

On the server, it:

1. Logs into GitHub Container Registry.
2. Checks whether the `db` container is running.
3. Creates a pre-deploy PostgreSQL backup if the database is available.
4. Keeps only the 10 newest backup dumps in `/opt/backups/whoknows/`.
5. Pulls the newest `web` image with `docker compose pull web`.
6. Restarts only the app container with `docker compose up -d --no-deps web`.
7. Runs a post-deploy smoke check against `http://127.0.0.1:8080/`.
8. Prints `docker compose logs web` and fails the deployment if the smoke check does not pass.

The backup step is warning-only. If a backup cannot be created, the deploy continues, because blocking every deployment on backup availability could leave us unable to ship an urgent fix. If the database container is running, the dump is created with `pg_dump --format=custom`, so it can later be restored with `pg_restore`.

Migrations are still handled by the app startup flow, as described in [Postgres Migrations](../database/postgres-migration.md). Sequel tracks applied migrations, so running migrations during startup is safe when the schema is already up to date.

The local `ruby-app/compose.yaml` is useful for local development and CI health checks. Production deployment assumes a Compose setup already exists on the server at the SSH target path. The image and container model are documented further in [Docker](./docker.md).

## Documentation Deployment

Documentation deployment is handled by `.github/workflows/docs.yml`, not the app CD workflow.

It runs on pushes to `main` when files under `documentation/**` or `mkdocs.yml` change. The workflow installs MkDocs Material and publishes the documentation site to GitHub Pages with `mkdocs gh-deploy --force`.

Keeping docs deployment separate gives it only the permissions it needs and prevents documentation-only changes from touching production app deployment.

## Pipeline Review

The current split is deliberate:

- `CI.yaml` validates app code and publishes the deployable image.
- `CD.yaml` deploys production and uses production secrets.
- `docs.yml` publishes documentation to GitHub Pages.
- `rubocop.yaml` gives review-friendly lint feedback on PRs.

The main CI workflow now uses parallel jobs where it makes sense. Tests and RuboCop do not depend on each other, so they run at the same time. Docker build waits for both because we only want to spend build and smoke-test time on code that has passed the basic quality gate. Docker push stays last because CD depends on a valid image in GHCR.

One possible future improvement is to move the RuboCop PR comment into the main CI workflow. For now, keeping it separate is useful because the blocking lint job can stay simple while the review workflow focuses on comments and permissions.

Post-deploy confidence is handled in two layers: CD now checks that the app responds immediately after restart, and [Postman Monitoring](../testing/postman-monitoring.md) keeps checking deployed endpoints every few hours.

## Dependency Maintenance

Dependabot is configured for:

- Bundler dependencies in `/ruby-app`
- GitHub Actions in `/`

Both run weekly. This keeps Ruby dependencies and workflow actions visible as regular pull requests instead of silent drift.

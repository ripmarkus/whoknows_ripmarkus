# CI/CD

## CI (OLD)

At the time of writing, our CI checks focus on compiling the app and linting the code using RuboCop, configured via a .rubocop.yml in the project root. This file defines our code style and complexity rules, ensuring consistent standards are enforced on every PR created.

Once linting is complete, the results are automatically posted as a comment on the Pull Request. If a report already exists from a previous run, it is overwritten rather than duplicated. 

This ensures every PR has an up-to-date summary of code quality issues directly on the Pull Request for review.

By enforcing these steps, we ensure that every Pull Request meets our baseline standards for code quality and maintainability, allowing us to run a tight ship throughout the development lifecycle.

**Why not locally?**

Running Ruboco locally is definitely a possibility, however running it in our CI flow, allows all developers to see what can be done better with our code quality, before they can submit the code - This nudges our team to fix issues instead of only fixing issues when they become a bigger problem.

### PostgreSQL in CI

After migrating to PostgreSQL, the test job spins up a `postgres:16-alpine` service container alongside the test runner. The `DATABASE_URL` environment variable is passed to RSpec so the app connects to this ephemeral database instead of SQLite. Migrations are applied automatically at the start of the test suite, and the database is torn down with the container when the job ends. This means tests always run against a real PostgreSQL instance, catching any SQL incompatibilities that would not appear with an in-memory database.

## CD

The deployment job connects to the production server via SSH and runs Docker Compose to pull the latest image and restart the app. Migrations are applied automatically when the container starts, since the `command` in `docker-compose.yml` runs `ruby db/migrate.rb` before launching the app. Sequel tracks which migrations have already been applied, so this step is always safe to run and has no effect if the schema is already up to date.

Before taking the app down, the pipeline dumps the current PostgreSQL database to `/opt/backups/whoknows/` using `pg_dump`. This gives a restore point in case a deploy introduces a regression. Only the ten most recent dumps are kept to prevent unbounded disk growth. To restore from a backup, run `pg_restore` against the relevant `.dump` file.

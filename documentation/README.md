# Documentation

Everything we've written down about the project lives here. Documentation is our version of the Sharing principle from CALMS, the idea that a system nobody can explain isn't really maintainable, and knowledge locked in one person's head is a bottleneck waiting to happen. Pick the folder that matches what you're looking for.

---

## Architecture

The shape of the system. The [dependency graph](./architecture/dependency-graph.md) maps out how services connected in the legacy app, and [open-api](./architecture/open-api.md) lists every endpoint and contract.

---

## Development

Getting your hands in the code. [Branching strategy](./development/branching-strategy.md) keeps us from stepping on each other, [contributions](./development/contributions.md) walks through submitting changes, and [init setup](./development/init_pages%20and%20init_db.md) gets your local environment running.

---

## DevOps

Moving code from laptops to production. [CI/CD](./devops/ci-cd.md) covers the pipeline, [docker](./devops/docker.md) handles containers, [devops-and-us](./devops/devops-and-us.md) explains the broader philosophy, and [code review](./devops/coderabbit-review.md) is about keeping quality high.

---

## Database

[Postgres migrations](./database/postgres-migration.md) holds the schema history and the reasoning behind each change.

---

## Testing

[How we test](./testing/testing.md) lays out frameworks and expectations, while [postman monitoring](./testing/postman-monitoring.md) covers API validation in production.

---

## Incidents

When things went sideways. The [post-mortem](./incidents/post-mortem-shuresm57.md) is a full breakdown, [python quirks](./incidents/problems-with-python-app.md) and [ruby quirks](./incidents/problems-with-ruby-app.md) track known issues, and [security breach](./incidents/security-breach.md) documents what happened and how we responded.

---

## Reports

[KPIs](./reports/KPI-report.md) track what's working, and [mandatory-1](./reports/mandatory-1/mandatory-1.md) holds the compliance paperwork.

---

## Reference

[Useful links](./reference/useful-links.md) is a running collection of tools and resources worth bookmarking.

---

## Ruby app

The Ruby app has its own docs: [API docs](./ruby-documentation/api-docs.md), [database config](./ruby-documentation/db-config.md), and [security](./ruby-documentation/security-docs.md).

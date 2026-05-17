# Service Level Agreement (SLA)

## Introduction

This document describes the Service Level Agreement (SLA) for the WhoKnows project.

The purpose of this SLA is to define what level of service users can expect from the system, how incidents are handled, and what maintenance and operational procedures are used to keep the application stable and available.

The project is a DevOps school project where an old Python2 application was refactored into Ruby/Sinatra and deployed using Docker, GitHub Actions, PostgreSQL and CI/CD practices.

---

## Service Overview

The WhoKnows project is a containerized Ruby/Sinatra web application modernized from an older Python2 codebase.

The system includes:

* A Ruby/Sinatra web application
* PostgreSQL database storage
* Docker-based containerization
* CI/CD pipelines through GitHub Actions
* Automated testing using RSpec
* Code quality checks using RuboCop and CodeRabbit
* Documentation via MkDocs
* Docker image publishing to GitHub Container Registry (GHCR)
* Monitoring and health checks

The application runs two services via Docker Compose:

| Service | Purpose                       |
| ------- | ----------------------------- |
| `web`   | Main Ruby/Sinatra application |
| `db`    | PostgreSQL database           |

The application uses persistent Docker volumes:

* `postgres_data` for PostgreSQL persistence
* `app_logs` for application logs

---

## Availability Target

We aim for:

| Metric                     | Target                 |
| -------------------------- | ---------------------- |
| Monthly uptime             | 99%                    |
| Planned maintenance notice | Minimum 24 hours       |
| Critical incident response | Within 1 hour          |
| Normal bug response        | Within 3 business days |

Since this is a student project, these are best-effort targets and not legally binding guarantees.

---

## Monitoring

## Health Checks

Docker health checks are set up for both services inside `compose.yaml`.

The PostgreSQL container uses:

```bash
pg_isready -U whoknows -d whoknows_test
```

The web application validates availability through:

```bash
wget -qO- http://127.0.0.1:8080/
```

The web service waits for the database to be healthy before starting:

```yaml
depends_on:
  db:
    condition: service_healthy
```

## CI/CD Validation

Every push is validated through GitHub Actions. The pipeline runs:

* RSpec tests
* RuboCop linting
* Docker image build validation
* Container startup verification
* Smoke testing through HTTP health checks

Deployments are blocked until all checks pass.

## Postman Monitoring

The project also uses Postman Monitoring to test selected endpoints every 6 hours.

Examples of monitored endpoints:

* `/`
* `/about`
* `/login`
* `/register`
* `/api/users`
* `/api/search`
* `/api/weather`

The monitoring verifies:

* HTTP status codes
* Response times
* API response structure
* Endpoint availability

---

# Incident Severity Levels

Incidents are categorized into different severity levels.

| Severity | Description                            | Example                     | Target Response Time |
| -------- | -------------------------------------- | --------------------------- | -------------------- |
| Critical | System unavailable or major data issue | Database down               | 1 hour               |
| High     | Major feature broken                   | Login system failing        | 4 hours              |
| Medium   | Partial functionality issue            | Search behaving incorrectly | 1 business day       |
| Low      | Minor UI or cosmetic issue             | Styling bug                 | 3 business days      |

---

# Backup and Recovery

## Database

The PostgreSQL database uses Docker volumes for persistent storage.

This ensures data survives:

* Container restarts
* Application redeployments
* Most deployment failures

## Recovery Strategy

In case of deployment failure:

1. The failing container is stopped
2. Previous stable image can be redeployed
3. Database volume remains intact
4. Check logs to find the cause

The project also stores source code in GitHub, making rollback possible through Git version control.

---

# Deployment Process

Deployments are automated using GitHub Actions.

## CI Pipeline

The project uses a GitHub Actions workflow called `Ruby CI`.

The CI pipeline:

1. Starts a PostgreSQL test service
2. Runs RSpec automated tests
3. Builds the Docker image
4. Starts the Docker Compose stack
5. Performs HTTP health checks using `curl`
6. Stops the containers after validation

It also handles RuboCop checks on pull requests, image publishing to GHCR, and MkDocs documentation deployment.

## CD Pipeline

The deployment workflow is triggered after successful CI validation.

The CD workflow:

1. Connects to the deployment server through SSH
2. Logs into GitHub Container Registry (GHCR)
3. Creates a pre-deployment PostgreSQL backup when possible
4. Pulls the newest Docker image
5. Restarts only the web container using Docker Compose

The database container stays running during web deployments, and old backups are cleaned up automatically.
This reduces the chance of broken deployments reaching production.

---

# Maintenance Windows

Planned maintenance may occur during:

* Dependency upgrades
* Security patches
* Database migrations
* Infrastructure improvements

When possible, maintenance should be announced at least 24 hours before downtime.

---

# Security and Reliability

## Security Measures

The project uses:

* Environment variables for secrets and configuration
* PostgreSQL authentication
* Docker container isolation
* GitHub Secrets for deployment credentials
* CI/CD validation before deployment
* RuboCop code quality checks
* CodeRabbit pull request reviews
* SSH-based deployment authentication

## Reliability Measures

* Automated tests
* Health checks
* Persistent Docker volumes
* CI/CD automation
* Smoke testing
* Monitoring

---

# Compliance Standards

Because this is a student project, the system is not formally certified against standards such as ISO 27001 or SOC 2.

However, the project follows common DevOps and operational best practices including:

* Version control through GitHub
* CI/CD validation before deployment
* Containerized infrastructure
* Automated testing and monitoring
* Persistent database storage
* Health checks and backup procedures
* Secret management through environment variables and GitHub Secrets

The project also attempts to follow GDPR-aware practices by not storing unnecessary sensitive personal information.

---

# Limitations

As this is a school project, some limitations exist.

The system:

* Does not have 24/7 operational support
* Does not guarantee enterprise-grade uptime
* Does not include multi-region redundancy
* Has limited scaling capabilities
* Relies on student-managed infrastructure

Despite this, DevOps practices are used to simulate a realistic deployment and maintenance workflow.

---

# Conclusion

This SLA defines the operational expectations for the WhoKnows-project.

The project focuses on reliability, automation, CI/CD, monitoring and maintainability using modern DevOps practices.

Even though the system is not a commercial production platform, the project demonstrates how service management, deployment workflows and operational procedures can be documented and maintained in a structured way.
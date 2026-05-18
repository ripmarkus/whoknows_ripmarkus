# Monitoring

We run a Prometheus and Grafana stack to track how the application behaves in production. Prometheus scrapes metrics from the app every 15 seconds and stores them. Grafana reads from Prometheus and visualizes the data in dashboards.

## Stack Overview

Prometheus runs on the app server and pulls metrics from:

- Our Sinatra app at `/metrics` (exposed on port 8080, restricted to `MONITORING_IP`)
- node_exporter for host-level CPU, memory, disk, network metrics

Grafana runs in Docker on a separate monitoring server, accessing Prometheus via internal network.

Dashboards are provisioned via GitOps: JSON files in the monitoring repo are automatically loaded by Grafana within 30 seconds of a push to main. No UI edits are persisted. All dashboard changes go through git commits.

## What We Monitor

### Business Metrics

The Business Observability dashboard shows how users interact with the product.

Successful logins track user retention. Search hit rate (successful searches over total searches) tells us if the search feature is useful. Registration count shows growth. Total search volume shows engagement.

The two keyword tables surface product intelligence: top searched terms show what users want, and top keywords with no results highlight content gaps where users look but find nothing.

## Security Metrics

The Security Observability dashboard monitors for potential attacks and auth failures.

Failed logins spike during brute force attacks. HTTP 401 (Unauthorized) and 403 (Forbidden) responses indicate access control issues. Failed registration attempts may signal spam or automated attack scripts.

The failed login rate panel includes thresholds to highlight unusual patterns. The total request rate baseline helps spot DDoS or scanning activity.

## Metrics Reference

All metrics live in the Prometheus registry exposed by the app at `/metrics`.

Counters (cumulative counts):

`login_attempts_total` with label `result` (success, failure)
`registrations_total` with label `result` (success, failure)
`password_changes_total` with label `result` (success, failure)
`search_queries_total` with labels `hit` (hit, miss) and `language` (latin, non_latin, unknown)
`search_keyword_total` with labels `keyword` (the search term, lowercased) and `hit` (hit, miss)
`http_requests_total` with labels `method`, `path`, `status_code`
`http_request_errors_total` with labels `method`, `path`, `error_class`
`weather_api_requests_total` with labels `phase`, `status_code`
`weather_api_errors_total` with labels `phase`, `error_class`

Histograms (distributions):

`http_request_duration_seconds` with labels `method`, `path`, `status_code`
`search_duration_seconds` with labels `language`, `hit`
`weather_api_duration_seconds` with labels `phase`, `status_code`

## Search Keyword Metric

The `search_keyword_total` counter is new and enables the business dashboard keyword tables.

When a user searches for something, we increment this counter with the query term (lowercased and stripped) and whether results were found. Blank searches (homepage load with no query) are skipped.

At this scale, cardinality is acceptable. If users conduct hundreds of unique searches daily, the metric label values stay manageable for Prometheus. If this changes, we can aggregate keywords or apply a top-k filter at scrape time.

## Grafana Access

Grafana runs at the monitoring endpoint with admin credentials in `.env`. All dashboards are read-only in the UI since they are file-provisioned. To modify a dashboard, edit the JSON in git and push to main.

Dashboard UIDs are unique identifiers used in URLs: `business-observability` and `security-observability`.

## Deployment

Push changes to the monitoring repo main branch. The GitHub Actions workflow SSHes into the monitoring server, runs `git pull`, and restarts docker-compose. Grafana detects new JSON files within its 30-second poll interval and loads them automatically.

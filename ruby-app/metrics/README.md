# Metrics

Prometheus instrumentation for the app, included via `MetricsHelpers`.

- `fetch_or_register_counter/histogram` — idempotent Prometheus metric registration
- Constants (`HTTP_REQUESTS_TOTAL`, `LOGIN_ATTEMPTS_TOTAL`, etc.) — pre-registered metrics, defined at load time after `PROM_REGISTRY` is available
- `metrics_path_label` — normalises a Sinatra route string into a label-safe path
- `skip_http_metrics?` — excludes `/metrics` and weather routes from HTTP tracking

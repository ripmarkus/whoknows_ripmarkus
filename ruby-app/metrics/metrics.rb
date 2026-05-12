# frozen_string_literal: true

def fetch_or_register_counter(registry, name, docstring:, labels: [])
  registry.get(name) || registry.counter(name, docstring:, labels:)
rescue Prometheus::Client::Registry::AlreadyRegisteredError
  registry.get(name)
end

def fetch_or_register_histogram(registry, name, docstring:, labels:, buckets:)
  registry.get(name) || registry.histogram(name, docstring:, labels:, buckets:)
rescue Prometheus::Client::Registry::AlreadyRegisteredError
  registry.get(name)
end

HTTP_REQUESTS_TOTAL = fetch_or_register_counter(
  PROM_REGISTRY,
  :http_requests_total,
  docstring: 'Total number of HTTP requests',
  labels: %i[method path status_code]
)

HTTP_REQUEST_DURATION_SECONDS = fetch_or_register_histogram(
  PROM_REGISTRY,
  :http_request_duration_seconds,
  docstring: 'HTTP request duration in seconds',
  labels: %i[method path status_code],
  buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2, 5]
)

HTTP_REQUEST_ERRORS_TOTAL = fetch_or_register_counter(
  PROM_REGISTRY,
  :http_request_errors_total,
  docstring: 'Total number of HTTP request failures',
  labels: %i[method path error_class]
)

LOGIN_ATTEMPTS_TOTAL = fetch_or_register_counter(
  PROM_REGISTRY,
  :login_attempts_total,
  docstring: 'Total login attempts',
  labels: %i[result]
)

REGISTRATIONS_TOTAL = fetch_or_register_counter(
  PROM_REGISTRY,
  :registrations_total,
  docstring: 'Total registrations',
  labels: %i[result]
)

PASSWORD_CHANGES_TOTAL = fetch_or_register_counter(
  PROM_REGISTRY,
  :password_changes_total,
  docstring: 'Total password change attempts',
  labels: %i[result]
)

SEARCH_QUERIES_TOTAL = fetch_or_register_counter(
  PROM_REGISTRY,
  :search_queries_total,
  docstring: 'Total number of search queries',
  labels: %i[language hit]
)

SEARCH_DURATION_SECONDS = fetch_or_register_histogram(
  PROM_REGISTRY,
  :search_duration_seconds,
  docstring: 'Search request duration in seconds',
  labels: %i[language hit],
  buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2]
)

WEATHER_API_REQUESTS_TOTAL = fetch_or_register_counter(
  PROM_REGISTRY,
  :weather_api_requests_total,
  docstring: 'Total number of outbound requests to the OpenWeather API',
  labels: %i[phase status_code]
)

WEATHER_API_DURATION_SECONDS = fetch_or_register_histogram(
  PROM_REGISTRY,
  :weather_api_duration_seconds,
  docstring: 'Duration of outbound OpenWeather API requests in seconds',
  labels: %i[phase status_code],
  buckets: [0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2, 5]
)

WEATHER_API_ERRORS_TOTAL = fetch_or_register_counter(
  PROM_REGISTRY,
  :weather_api_errors_total,
  docstring: 'Total number of outbound OpenWeather API errors',
  labels: %i[phase error_class]
)

module MetricsHelpers
  def metrics_path_label(env)
    route = env['sinatra.route']
    return '/unknown' if route.nil? || route.strip.empty?

    _method, path = route.split(' ', 2)
    normalized = path.to_s.strip
    normalized.empty? ? '/unknown' : normalized
  end

  def skip_http_metrics?(env)
    path = metrics_path_label(env)

    request.path_info == '/metrics' ||
      path == '/api/weather' ||
      path == '/weather'
  end
end

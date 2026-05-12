# Weather

OpenWeatherMap API helpers, included via `WeatherHelpers`.

- `weather_api_key` — reads the API key from the environment
- `safe_json_parse` — parses JSON with a logged fallback on error
- `http_get_json` — makes an outbound GET, records Prometheus metrics, and returns parsed JSON
- `get_weather_for` — geocodes a city then fetches current weather, returns combined payload

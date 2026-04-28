# Helpers

General-purpose helpers included into the Sinatra app via `AppHelpers`.

- `payload_value` — reads a key from a hash by string or symbol
- `json` — sets content type and serialises a response to JSON
- `monotonic_now` — returns a monotonic clock timestamp
- `parsed_json_body` / `request_payload` — reads and parses the request body
- `safe_status_code` — safely extracts an HTTP status code string
- `json_request?` — true if the request is JSON or under `/api/`

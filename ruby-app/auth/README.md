# Auth

Authentication and authorisation helpers, included via `AuthHelpers`.

- `hash_password` / `password_matches?` — BCrypt password hashing and verification
- `validate_registration_fields` — validates username, email, and password fields
- `find_user_for_login` — looks up a user by email or username
- `allowed_ip?` / `current_request_ip` — IP allowlist check for protected endpoints

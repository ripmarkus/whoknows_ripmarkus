# Testing

## Run tests

```bash
cd ruby-app
bundle install
bundle exec rspec --format documentation
```

## Test types implemented

### Unit tests (`spec/unit/`)
- **validation_spec.rb** - Tests `validate_registration_fields` (missing username, bad email, blank password, mismatched passwords, valid input)
- **security_spec.rb** - Tests `hash_password` and `password_matches?` (BCrypt hashing and verification)

### Integration tests (`spec/integration/`)
- **api_spec.rb** - Tests API endpoints (`/api/search`, `/api/register`, `/api/login`) with real HTTP requests via `rack-test`
- **views_spec.rb** - Tests HTML routes (`/`, `/about`, `/login`) return 200

## Test types considered but not implemented

| Type | Reason skipped |
|------|---------------|
| E2E / Playwright | App is small with few interactive flows; `rack-test` integration tests cover the same routes without browser overhead |
| Performance / load testing | Not a high-traffic app; no performance SLAs to validate |
| Smoke tests | The CI Docker health check (`curl -f http://localhost:8080/`) already serves this purpose |

## CI

Tests run automatically in GitHub Actions (`CI.yaml`) on push/PR to `main`. The Docker build step depends on tests passing.

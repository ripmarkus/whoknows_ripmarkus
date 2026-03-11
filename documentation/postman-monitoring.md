# API Monitoring

## Purpose

To ensure the application continues running after deployment, we have set up automated monitoring using **Postman Monitoring**.

The monitor periodically sends requests to the deployed application and runs tests on the responses. This allows us to detect problems early if something stops working.

The monitor helps verify:

- If endpoints are reachable
- If the API returns the expected response format
- If responses arrive within a reasonable time
- If routes accidentally break after changes

---

## Monitoring Schedule

The Postman monitor is configured to run **every 3 hours**.

Each run executes the full request collection and records:

- Response status codes
- Response times
- Test results
- Any failures

---

## Monitored Endpoints

The monitor currently checks the following endpoints:

| Endpoint | Method | Purpose |
|--------|--------|--------|
| `/` | GET | Checks that the frontpage returns successfully. |
| `/about` | GET | Checks that the about page returns successfully. |
| `/login` | GET | Checks that the login page returns successfully. |
| `/register` | GET | Checks that the register page returns successfully. |
| `/weather` | GET | Checks that the weather page returns successfully. |
| `/api/users` | GET | Tests the users API |
| `/api/search` | GET | Tests the search API |
| `/api/weather` | GET | Tests the weather API |
| `/api/register` | POST | Tests the user registration endpoint |
| `/api/login` | POST | Tests the login endpoint |
| `/api/logout` | POST | Tests the logout endpoint |

---

## Collection Configuration + Shared Tests

### Base URL Variable

To avoid repeating the domain in every request, we use a **collection variable**.

This makes it easy to change the deployment URL without modifying every endpoint.

![Base URL variable configuration](/documentation/imgs/2026-03-10_18-10.png)

Requests are then written like this:

![Example request using BASE_URL](/documentation/imgs/2026-03-10_18-12.png)
![Example request using BASE_URL](/documentation/imgs/2026-03-10_18-17.png)

---

### Shared Tests

All endpoints in our monitoring collection use a couple of basic tests to verify that the application is responding correctly.

These tests run for every request in the collection.

![Shared tests example](/documentation/imgs/2026-03-10_18-21.png)

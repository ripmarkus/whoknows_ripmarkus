
# Our OpenAPI
## Purpose
We want all developers to have a clear overview of our API and page endpoints, so we have an overview on the site itself.

The route /api/docs is an on premise Swagger/OpenAPI UI. The purpose it serves is to interact with the API directly from our browsers, and to test all of our endpoints.

![OpenAPI](./imgs/OpenAPIpage.png)


## HTML Routes
The specification also documents routes used for rendering pages in the browser:

- `/` – Main page. Supports the parameters `query` and `language`.
- `/about` – Page containing information about the project.
- `/login` – Page used for user login.
- `/register` – Page used for creating a new account.
- `/weather` – Displays weather data based on `city` and `country`.

## API Endpoints
The API routes are defined under the `/api` path.

- `GET /api/users` – Returns user data.
- `GET /api/search` – Performs a search based on `query` and `language`.
- `GET /api/weather` – Returns weather information for a specified location.

## Authentication Endpoints
User authentication is handled through the following endpoints:

- `POST /api/register` – Registers a new user.
- `POST /api/login` – Authenticates a user.
- `POST /api/logout` – Ends the user session.


---

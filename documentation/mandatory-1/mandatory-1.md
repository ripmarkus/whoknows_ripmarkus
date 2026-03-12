# Mandatory 1 - ripmarkus

### Kristian, Valdemar, Niko & Mathias

---

This is a mandatory hand-in for the Computer Science elective DevOps on EK.


_This is a collection of documentation, that reflects the state of the project on 13/03/2026. Refer to the repository documentation for the latest updates._

Use the links below to navigate to the relevant section.

- [Dependency Graph](#dependency-graph)
- [Problems With Legacy Codebase](#problems-with-legacy-codebase)
- [Our OpenAPI](#our-openapi)
- [Branching Strategy](#branching-strategy)

---

# Dependency Graph

graph TD
    subgraph External Libraries
        flask[Flask]
        sqlite3[sqlite3]
        hashlib[hashlib]
        pathlib[pathlib]
        os_sys[os / sys]
    end

    subgraph Configuration
        config["DATABASE_PATH, SECRET_KEY, DEBUG"]
    end

    subgraph Database
        connect_db[connect_db]
        check_db_exists[check_db_exists]
        init_db[init_db]
        query_db[query_db]
        get_user_id[get_user_id]
    end

    subgraph Request Handlers
        before_request[before_request]
        after_request[after_request]
    end

    subgraph Security
        hash_password[hash_password]
        verify_password[verify_password]
    end

    subgraph Page Routes
        route_root[GET /]
        route_about[GET /about]
        route_login[GET /login]
        route_register[GET /register]
    end

    subgraph API Routes
        api_search[GET /api/search]
        api_login[POST /api/login]
        api_register[POST /api/register]
        api_logout[GET /api/logout]
    end

    pathlib --> config
    config --> connect_db
    sqlite3 --> connect_db
    os_sys --> check_db_exists
    connect_db --> check_db_exists
    init_db --> connect_db

    hashlib --> hash_password
    hash_password --> verify_password

    before_request --> connect_db
    before_request --> query_db

    route_root --> query_db
    api_search --> query_db
    api_login --> query_db
    api_login --> verify_password
    api_register --> query_db
    api_register --> get_user_id
    api_register --> hash_password
    get_user_id --> query_db

# Problems With Legacy Codebase

## Converting from Python2 -> Python3
We used the `2to3` module (installed via pip) to ensure Python 3 compatibility across the application.

## Making the database path work no matter the machine (Relative)
To ensure the database works regardless of the machine's file system, we implemented relative paths using the `pathlib` module.
```python
DATABASE_PATH = Path(__file__).resolve().parent.parent / "schema.sql"
```

## API Routes
The app mixed page routes and API routes without clear separation. For example, `/login` renders a page while `/api/login` handles the form submission, but there was no consistent structure enforcing this.
```python
@app.route('/login')
def login():
    """Displays the login page."""
    if g.user:
        return redirect(url_for('search'))
    return render_template('login.html')

@app.route('/api/login', methods=['POST'])
def api_login():
    """Logs the user in."""
    ...
```

## SQL Injection Vulnerabilities
Almost every query in the app is vulnerable to SQL injection because user input is pasted directly into the query string using % formatting. A user could type something like `' OR '1'='1` and mess with the query entirely.
```python
g.user = query_db("SELECT * FROM users WHERE id = '%s'" % session['user_id'], one=True)
search_results = query_db("SELECT * FROM pages WHERE language = '%s' AND content LIKE '%%%s%%'" % (language, q))
g.db.execute("INSERT INTO users (username, email, password) values ('%s', '%s', '%s')" % 
             (request.form['username'], request.form['email'], hash_password(request.form['password'])))
```

## Password Safety
The python app used MD5 hashing, which is not that secure for passwords, since it is cryptographically broken and easy to crack with an online tool like https://crackstation.net. It should be using bcrypt, which we will implement in the ruby code.
```python
def hash_password(password):
    """Hash a password using md5 encryption."""
    password_bytes = password.encode('utf-8')
    hash_object = hashlib.md5(password_bytes)
    password_hash = hash_object.hexdigest()
    return password_hash
```

## Hardcoded Secret Key
The `SECRET_KEY` is set to `'development key'` right in the source code. This key is used to sign session cookies, so anyone who sees the code can forge them. It should be set via an environment variable, so nobody but us can access it.
```python
SECRET_KEY = 'development key'
app.secret_key = SECRET_KEY
```

## Debug Mode
The debug mode is hardcoded to false instead of set up in environmental variables, which requires the programmer to manually edit the source file and may accidentally commit the change to production and expose app info.
```python
DEBUG = False
app.run(host="0.0.0.0", port=8080, debug=DEBUG)
```

---

# Our OpenAPI

## Purpose
We want all developers to have a clear overview of our API and page endpoints, so we have an overview on the site itself.

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

## Interactive Documentation
The specification is visualized using **Swagger UI**.
The documentation is available locally at:

`http://91.100.1.101/api/docs`

---

# Branching Strategy

## 1. Chosen Version Control Strategy

We chose to use **GitHub Flow** as our branching strategy.

GitHub Flow is a lightweight, feature-branch-based workflow centered around a stable `main` branch.

### Repository Structure

- `main` → Always stable and production-ready
- `feat/*`, `fix/*`, `documentation/*`, `chore/*` → Short-lived branches created from `main`, used for features, fixes, documentation or chores
- Pull Requests (PRs) → Required before merging into `main`

All new features, bug fixes, and documentation updates are developed in separate feature branches and merged back into `main` via PRs.

---

## Enforcement of the Strategy

We enforce our branching strategy through the following rules:

- Direct pushes to `main` are NOT allowed
- Developers CANNOT review or approve their own PR
- At least one team member must review and approve a PR
- Only after approval can the PR be merged
- Feature branches are deleted after merge

This ensures:

- A strong code review culture
- Shared ownership of the codebase
- Higher code quality
- Fast and continuous delivery of features
- Reduced risk of unstable or unwanted code reaching `main`

By preventing self-review, all code changes are validated by another team member. This increases accountability and collaboration among the team.

---

## 2. Why We Chose GitHub Flow

We chose GitHub Flow because:

- We are a small team
- Our project does not require complex release cycles
- We wanted a simple and efficient workflow

GitHub Flow supports continuous integration principles and keeps the workflow very easy to understand and maintain.

### Why We Did Not Choose Git Flow

We did not choose Git Flow because:

- It introduces additional branches such as `develop`, `release`, and `hotfix`
- It adds unnecessary process overhead for our team size
- It is better suited for larger teams with structured release planning

For our project, Git Flow would have introduced more complexity without any clear added value.

### Why We Did Not Choose Trunk-Based Development

We did not choose Trunk-Based Development because:

- It requires very mature CI/CD pipelines
- It relies heavily on automated testing
- It demands small frequent code changes directly into `main`

As a student team, we preferred a more controlled approach where PRs and code-reviews act as a safety mechanism before changes reach `main`.

---

## 3. Advantages and Disadvantages

*(Feel free to add to 'Advantages' or 'Disadvantages' if new insight is gained or you feel like something is missing)*

### Advantages

- Mandatory code review improves quality
- Simple workflow
- Increased knowledge sharing across the team
- Structured and readable Git history
- Reduced risk of breaking `main`

### Disadvantages

- PRs can slow development if reviewers are unavailable or not looking for new PRs to merge
- Requires discipline to keep branches small and focused
- Workflow heavily depends on the team's responsiveness and level of activeness
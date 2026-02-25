# Problems

## Converting from Python2 -> Python3
    We used the `2to3` module (installed via pip) to ensure Python 3 compatibility across the application.

## Making the database path work no matter the machine (Relative)
    To ensure the database works regardless of the machine's file system, we implemented relative paths using the `pathlib` module.


## API Routes
    The app mixed page routes and API routes without clear separation like API endpoints like  /api/login, /api/register and /api/search.

## SQL Injection Vulnerabilities
    Almost every query in the app is vulnerable to SQL injection because user input is pasted directly into the query string using % formatting, like "SELECT * FROM users WHERE username = '%s'" % username. A user could type something like ' OR '1'='1 and mess with the query entirely.

## Password Safety

    The python app used MD5 hashing, which is not that secure for passwords, since it is cryptographically broken and easy to crack with an online tool like https://crackstation.net. It should be using bcrypt, which we will implement in the ruby code.

## Hardcoded Secret Key
    The SECRET_KEY is set to 'development key' right in the source code. This key is used to sign session cookies, so anyone who sees the code can forge them. It should be set via an environment variable, so nobody but us can access it.

## Debug mode
    The debug mode is hardcoded to false instead of set up in enviromental variables, which requires the programmer to manually edit the source file and may accidentally commit the change to production and expose app info.
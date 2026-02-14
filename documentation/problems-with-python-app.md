# Problems

## Converting from Python2 -> Python3
    We used the `2to3` module (installed via pip) to ensure Python 3 compatibility across the application.

## Making the database path work no matter the machine (Relative)
    To ensure the database works regardless of the machine's file system, we implemented relative paths using the `pathlib` module.


## API Routes

## Password Safety

The python app used MD5 hashing, which is not that secure for passwords, since it is cryptographically broken and easy to crack with an online tool like https://crackstation.net. It should be using bcrypt, which we will implement in the ruby code.
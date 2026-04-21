# Security Documentation

## Bcrypt

We never want to know the true value of a password string but we do want to check that a plaintext matches a password - and that is where Bcrypt comes in.

```ruby
def hash_password(password)
  BCrypt::Password.create(password)
end

def password_matches?(password_hash, plaintext_password)
  BCrypt::Password.new(password_hash) == plaintext_password
end
```

## For storing passwords

```ruby
def hash_password(password)
```

This method takes a plaintext string as parameter, and will hash it, so that the stored value of the string is unreadable by humans. Should be used before registering a password.

## For matching passwords

```ruby
def password_matches?(password_hash, plaintext_password)
```

When retrieving a password from the database, we want to check if it matches the string that is provided by a user. Returns `true` if they match, `false` if not.

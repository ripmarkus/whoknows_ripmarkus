# Security Breach Response

A hacker gained read access to the database and sent a sample of user credentials as proof. No write access was obtained and the systems were not compromised beyond data exposure.

## What changed

A `password_reset_required` column was added to the users table. All existing users have the flag set to 1, which forces them to change their password on next login. New registrations always set the flag to 0. Once a user successfully changes their password, the flag is cleared and they can use the app normally.

## How it works

Every request from a logged-in user is intercepted by a `before` filter in `app.rb`. If the user's `password_reset_required` flag is 1, they are redirected to `/change-password` regardless of where they are trying to go. The only routes exempt from this redirect are `/change-password` itself and `/logout`.

The change-password page asks for the current password as verification, then a new password and confirmation. On success the new password is hashed with BCrypt and saved, and the reset flag is cleared.

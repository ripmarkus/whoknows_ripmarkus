# Database Test Setup

This project includes two Ruby scripts used to initialize and populate a SQLite database (`whoknows.db`) for testing.

## init_db.rb

- Creates the database schema.
- Drops and recreates the `users` table.
- Inserts a default admin user.
- Creates the `pages` table with fields:
  - `title` (primary key)
  - `url`
  - `language` (`en` or `da`)
  - `last_updated`
  - `content`

## init_pages.rb

- Clears all existing data in the `pages` table.
- Inserts a small set of test pages.
- Uses `INSERT OR REPLACE` to avoid duplicates.
- Prints confirmation of inserted records.

## Usage

Run the scripts in order:

```bash
ruby init_db.rb
ruby init_pages.rb
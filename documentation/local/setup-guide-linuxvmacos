# whoknows — Developer Setup Guide
> macOS · Linux · PostgreSQL 18 · Ruby

---

## Step 1 — Install Ruby Dependencies

Navigate into the project folder and install all gems:

```bash
cd ruby-app
bundle install

# Install and build Tailwind CSS
gem install tailwindcss-ruby
bundle exec tailwindcss -i public/input.css -o public/output.css
```

> **Note:** This project uses Tailwind CSS v4 syntax in `public/input.css` (`@import "tailwindcss"`). If the build fails with `Failed to find 'tailwindcss'`, your local bundle is still on Tailwind 3.x. Update the gem to `tailwindcss-ruby ~> 4.0`, run `bundle update tailwindcss-ruby`, and then rerun the build command above.

> **Note:** If the Tailwind commands fail, skip them for now and return to this step later.

---

## Step 2 — Install PostgreSQL 18

**macOS (Homebrew):**

```bash
brew install postgresql@18
brew services start postgresql@18
```

Add PostgreSQL to your PATH by appending this to your `~/.zshrc` or `~/.bash_profile`:

```bash
export PATH="/opt/homebrew/opt/postgresql@18/bin:$PATH"
```

Then reload your shell:

```bash
source ~/.zshrc   # or source ~/.bash_profile
```

**Linux (Debian/Ubuntu):**

```bash
sudo apt install -y postgresql-18
sudo systemctl enable --now postgresql
```

---

## Step 3 — Configure `pg_hba.conf`

Open the config file in your editor. The location varies by platform:

- **macOS (Homebrew):** `/opt/homebrew/var/postgresql@18/pg_hba.conf`
- **Linux:** `/etc/postgresql/18/main/pg_hba.conf`

Find every entry where the `METHOD` column reads `scram-sha-256` or `peer` and change it to `trust`. The finished file should look like this:

```conf
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             all                                     trust
host    all             all             127.0.0.1/32            trust
host    all             all             ::1/128                 trust
local   replication     all                                     trust
host    replication     all             127.0.0.1/32            trust
host    replication     all             ::1/128                 trust
```

> ⚠️ **Security note:** Setting the method to `trust` disables password authentication for the local PostgreSQL service. This is intentional for local development — never do this on a publicly accessible server.

---

## Step 4 — Restart the PostgreSQL Service

**macOS:**

```bash
brew services restart postgresql@18
```

**Linux:**

```bash
sudo systemctl restart postgresql
```

---

## Step 5 — Create the Database

The default superuser on most installations is `postgres`. Create the application database:

```bash
createdb -U postgres whoknows
```

> **macOS tip:** Homebrew may set the default user to your macOS username instead of `postgres`. If the above fails, try `createdb whoknows` without the `-U` flag, or run `psql postgres` to check which user you are.

---

## Step 6 — Restore the Database Dump

Replace the empty database with the provided SQL dump:

```bash
psql -h 127.0.0.1 -U postgres -d whoknows -f ./full_dump.sql
```

This connects to your running PostgreSQL instance and imports the full schema and data from the dump file.

---

## Step 7 — Configure Environment Variables

Look for the `.env` file in the root of the `ruby-app` directory. These variables are automatically loaded when the application starts:

```env
OPENWEATHER_API_KEY=<your_key>
POSTGRES_DB=whoknows
POSTGRES_USER=postgres
POSTGRES_PASSWORD=
DATABASE_URL=postgres://postgres@localhost:5432/whoknows
MONITORING_IP=<your_ip>
```

> **Tip:** `DATABASE_URL` is the most important variable. Check the application code if you are unsure which of the others are required.

---

**You're all set!** Start the application and verify everything is working.
# whoknows — Developer Setup Guide
> Windows · PostgreSQL 18 · Ruby

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

```bash
winget install PostgreSQL.PostgreSQL.18
```

---

## Step 3 — Configure `pg_hba.conf`

Open the config file in your editor. On Windows it is typically located at:

```
C:\Program Files\PostgreSQL\18\data\pg_hba.conf
```

Find every entry where the `METHOD` column reads `scram-sha-256` and change it to `trust`. The finished file should look like this:

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

Open PowerShell **as Administrator** and run:

```powershell
Restart-Service postgresql-x64-18
```

Also add the PostgreSQL bin directory to your `PATH` so commands like `createdb` are available everywhere:

```
C:\Program Files\PostgreSQL\18\bin
```

---

## Step 5 — Create the Database

The default user created by the winget installer is `postgres`. Create the application database:

```bash
createdb -U postgres whoknows
```

---

## Step 6 — Restore the Database Dump

Replace the empty database with the provided SQL dump:

```bash
psql -h 127.0.0.1 -U postgres -d whoknows -f .\full_dump.sql
```

This connects to your running PostgreSQL instance and imports the full schema and data from the dump file.

---

## Step 7 — Configure Environment Variables

Look for the '.env' file in the root of the `ruby-app` directory. These variables are automatically loaded when the application starts:

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
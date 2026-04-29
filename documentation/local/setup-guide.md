# Prerequisites
```bash
cd ruby-app
bundle install
bundle exec tailwindcss -i public/input.css -o public/output.css
```

You will also need to download and install postgres..
Windows:
```bash
winget install PostgreSQL.PostgreSQL.18
```
Once this step is complete, you will want to edit your pg_hba.conf file...
It is often on windows located here: C:\Program Files\PostgreSQL\18\data\pg_hba.conf
Open your editor:
```conf
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             all                                     trust
host    all             all             127.0.0.1/32            trust
host    all             all             ::1/128                 trust
local   replication     all                                     trust
host    replication     all             127.0.0.1/32            trust
host    replication     all             ::1/128                 trust
```
In here you want to replace the method 'sha-bla-bla' to trust..
This disables passwords on your local psql service - which is perfect, since the point is not exposing the db..
After this, you will have to restart the service. Open up powershell with administrator privileges and run:
```bash
restart-Service postgresql-x64-18
```
You will also have to add this directory: 'C:\Program Files\PostgreSQL\18\bin' to your path, for easier use..

It is also important to note, that when you install postgres with winget the default user is 'postgres' and by changing your method from 'sha' to trust, you are basically disabling password auth for postgres..

When this step is complete, you will have to create a new database...
```bash
createdb -U postgres whoknows
```

After this you will have to replace your newly created and empty db with your dump... 
```bash
psql -h 127.0.0.1 -U postgres -d whoknows -f .\full_dump.sql
```
This line opens a connection to your already running postgress db, with the username postgres, database name whoknows, and at last the path to your SQL dump..



Once you're here you will want to change your environmental variables.. The variables are automatically loaded into the ruby program, once it starts..
```env
OPENWEATHER_API_KEY=set
POSTGRES_DB=set
POSTGRES_USER=set
POSTGRES_PASSWORD=set
DATABASE_URL=postgres://postgres@localhost:5432/whoknows
MONITORING_IP=set
```


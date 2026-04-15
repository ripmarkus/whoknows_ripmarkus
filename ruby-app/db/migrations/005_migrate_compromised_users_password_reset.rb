# migrate_compromised_users_password_reset.rb
require "sqlite3"

DB_PATH = ARGV[0] || File.expand_path("db/app.db", __dir__)

COMPROMISED_USERS = [
  { username: "Eric1986",    email: "solveig951986@example.net" },
  { username: "Frederik2005", email: "robin612005@example.com" },
  { username: "Ziggy1958",   email: "dahljimmy1958@example.org" },
  { username: "Yngve1975",   email: "nicolaimikkelsen1975@example.com" },
  { username: "Ellen2013",   email: "wkjeldsen2013@example.com" },
  { username: "Johnnie1998", email: "benthefriis1998@example.net" },
  { username: "Boe1978",     email: "danielsenjakob1978@example.org" },
  { username: "Alvin2005",   email: "friisrikke2005@example.net" },
  { username: "Rita1997",    email: "ebbe251997@example.org" },
  { username: "Claus1976",   email: "ragnermogensen1976@example.net" },
  { username: "Kim2019",     email: "bhenriksen2019@example.org" },
  { username: "Victor2023",  email: "robinfrederiksen2023@example.net" },
  { username: "Abelone1950", email: "carlsenalvin1950@example.com" },
  { username: "Birthe1946",  email: "cnissen1946@example.org" },
  { username: "Ronni1982",   email: "sinechristiansen1982@example.com" },
  { username: "Dina1990",    email: "qmikkelsen1990@example.org" },
  { username: "Karina1962",  email: "kurtbech1962@example.net" },
  { username: "Rebecca1960", email: "torbenkristoffersen1960@example.com" },
  { username: "Victoria1976", email: "jarl641976@example.org" },
  { username: "Søs1988",     email: "xeriksen1988@example.org" }
].freeze

unless File.exist?(DB_PATH)
  abort "Database findes ikke: #{DB_PATH}"
end

db = nil

begin
  db = SQLite3::Database.new(DB_PATH)
  db.results_as_hash = true

  columns = db.execute("PRAGMA table_info(users)")
  has_reset_column = columns.any? { |col| col["name"] == "password_reset_required" }

  db.transaction

  unless has_reset_column
    db.execute <<~SQL
      ALTER TABLE users
      ADD COLUMN password_reset_required INTEGER NOT NULL DEFAULT 0
    SQL
    puts "Tilføjede kolonnen password_reset_required med default 0."
  else
    puts "Kolonnen password_reset_required findes allerede."
  end

  # Nulstil alle til 0 først, så migrationen bliver deterministisk
  db.execute("UPDATE users SET password_reset_required = 0")

  updated_count = 0
  missing_users = []

  COMPROMISED_USERS.each do |user|
    db.execute(
      "UPDATE users SET password_reset_required = 1 WHERE username = ? AND email = ?",
      [user[:username], user[:email]]
    )

    changes = db.get_first_value("SELECT changes()").to_i

    if changes > 0
      updated_count += changes
    else
      missing_users << "#{user[:username]} <#{user[:email]}>"
    end
  end

  db.commit

  puts "Satte password_reset_required = 1 for #{updated_count} kompromitterede bruger(e)."

  if missing_users.any?
    puts
    puts "Disse kompromitterede brugere blev ikke fundet i databasen:"
    missing_users.each { |u| puts "  - #{u}" }
  end

  total_flagged = db.get_first_value("SELECT COUNT(*) FROM users WHERE password_reset_required = 1")
  puts
  puts "Samlet antal brugere markeret til password reset: #{total_flagged}"

rescue SQLite3::Exception => e
  db.rollback rescue nil
  abort "SQLite-fejl: #{e.message}"
ensure
  db.close if db
end
# frozen_string_literal: true

require 'sequel'

# -------------------------
# Connections
# -------------------------
sqlite_path = File.join(__dir__, '../whoknows.db')
sqlite = Sequel.sqlite(sqlite_path)

pg = Sequel.connect(ENV.fetch('DATABASE_URL'))

puts "🚀 Starting SQLite → Postgres migration..."

# -------------------------
# USERS
# -------------------------
puts "👤 Migrating users..."

sqlite[:users].each do |user|
  pg[:users].insert(
    id: user[:id],
    username: user[:username],
    email: user[:email],
    password: user[:password]
  )
end

# fix sequence
pg.run <<~SQL
  SELECT setval('users_id_seq', (SELECT MAX(id) FROM users));
SQL

# -------------------------
# PAGES
# -------------------------
puts "📄 Migrating pages..."

sqlite[:pages].each do |page|
  pg[:pages].insert(
    title: page[:title],
    url: page[:url],
    language: page[:language],
    last_updated: page[:last_updated],
    content: page[:content]
  )
end

# -------------------------
# Rebuild search index
# -------------------------
puts "🔍 Rebuilding search vectors..."

pg.run <<~SQL
  UPDATE pages
  SET search_vector =
    to_tsvector('english', coalesce(title,'') || ' ' || coalesce(content,''));
SQL

puts "✅ Migration completed successfully!"
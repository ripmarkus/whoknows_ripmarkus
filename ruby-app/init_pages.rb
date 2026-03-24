# frozen_string_literal: true

require 'sqlite3'

db = SQLite3::Database.new('whoknows.db')

db.execute('DELETE FROM pages')

rows = [
  [
    'Java',
    'https://example.com/java',
    'en',
    '2026-03-24',
    'Java description'
  ],
  [
    'JavaScript',
    'https://example.com/javascript',
    'en',
    '2026-03-24',
    'JavaScript description'
  ],
  [
    'MATLAB',
    'https://example.com/matlab',
    'en',
    '2026-03-24',
    'Contains the word Java in content but should not match title search for java'
  ]
]

rows.each do |title, url, language, last_updated, content|
  db.execute(
    'INSERT OR REPLACE INTO pages (title, url, language, last_updated, content) VALUES (?, ?, ?, ?, ?)',
    [title, url, language, last_updated, content]
  )
end

puts 'Cleared pages table'
puts "Inserted #{rows.length} test pages into whoknows.db"

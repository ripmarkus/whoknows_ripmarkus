# frozen_string_literal: true

require 'sqlite3'

db = SQLite3::Database.new 'whoknows.db'

schema = <<~SQL
  DROP TABLE IF EXISTS users;

  CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL UNIQUE,
    email TEXT NOT NULL UNIQUE,
    password TEXT NOT NULL
  );

  INSERT INTO users (username, email, password)
  VALUES ('admin', 'keamonk1@stud.kea.dk', '5f4dcc3b5aa765d61d8327deb882cf99');

  CREATE TABLE IF NOT EXISTS pages (
    title TEXT PRIMARY KEY UNIQUE,
    url TEXT NOT NULL UNIQUE,
    language TEXT NOT NULL CHECK(language IN ('en', 'da')) DEFAULT 'en',
    last_updated TIMESTAMP,
    content TEXT NOT NULL
  );

  DROP TABLE IF EXISTS pages_fts;

  CREATE VIRTUAL TABLE pages_fts USING fts5(title, content, language, content='pages', content_rowid='rowid');

  CREATE TRIGGER IF NOT EXISTS pages_ai AFTER INSERT ON pages BEGIN
    INSERT INTO pages_fts(rowid, title, content, language) VALUES (new.rowid, new.title, new.content, new.language);
  END;

  CREATE TRIGGER IF NOT EXISTS pages_ad AFTER DELETE ON pages BEGIN
    INSERT INTO pages_fts(pages_fts, rowid, title, content, language) VALUES('delete', old.rowid, old.title, old.content, old.language);
  END;

  CREATE TRIGGER IF NOT EXISTS pages_au AFTER UPDATE ON pages BEGIN
    INSERT INTO pages_fts(pages_fts, rowid, title, content, language) VALUES('delete', old.rowid, old.title, old.content, old.language);
    INSERT INTO pages_fts(rowid, title, content, language) VALUES (new.rowid, new.title, new.content, new.language);
  END;
SQL

db.execute_batch(schema)

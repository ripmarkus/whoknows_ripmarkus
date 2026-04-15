# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

require 'rack/test'
require 'rspec'
require 'fileutils'
require 'sqlite3'

TEST_DB_PATH = File.join(__dir__, '..', 'whoknows_test.db')

def setup_test_db
  db = SQLite3::Database.new(TEST_DB_PATH)
  db.execute_batch(<<~SQL)
    DROP TABLE IF EXISTS users;
    DROP TABLE IF EXISTS pages;

    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL UNIQUE,
      email TEXT NOT NULL UNIQUE,
      password TEXT NOT NULL,
      password_reset_required INTEGER NOT NULL DEFAULT 0
    );
    CREATE TABLE pages (
      title TEXT PRIMARY KEY UNIQUE,
      url TEXT NOT NULL UNIQUE,
      language TEXT NOT NULL CHECK(language IN ('en', 'da')) DEFAULT 'en',
      last_updated TIMESTAMP,
      content TEXT NOT NULL
    );
    INSERT INTO pages (title, url, language, last_updated, content)
    VALUES ('Test Page', 'http://example.com', 'en', '2024-01-01', 'test content');
  SQL
  db.close
end

setup_test_db

require_relative '../app'

# Point app at test database
$VERBOSE = nil
Object.send(:remove_const, :DATABASE_PATH)
DATABASE_PATH = TEST_DB_PATH
$VERBOSE = true

RSpec.configure do |config|
  config.include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  config.before(:each) do
    clear_cookies
    setup_test_db
  end

  config.after(:suite) do
    FileUtils.rm_f(TEST_DB_PATH)
  end
end

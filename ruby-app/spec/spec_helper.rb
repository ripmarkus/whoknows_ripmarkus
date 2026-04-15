# frozen_string_literal: true

require 'rack/test'
require 'rspec'
require 'fileutils'
require 'sequel'

# Database file in ruby-app directory
TEST_DB_FILE = 'whoknows_test.db'
TEST_DB_PATH = File.join(__dir__, '..', TEST_DB_FILE)

ENV['RACK_ENV'] = 'test'
# SQLite URL format - Sequel expects sqlite:// for relative paths
# Use just the filename for relative path from where Sequel.connect is called
ENV['DATABASE_URL'] = "sqlite://#{TEST_DB_FILE}"

def setup_test_db
  # Remove existing database file
  FileUtils.rm_f(TEST_DB_PATH)
  
  # Create fresh database and tables - Sequel.sqlite() handles the file directly
  db = Sequel.sqlite(TEST_DB_PATH)
  
  db.create_table(:users) do
    primary_key :id
    String :username, null: false, unique: true
    String :email, null: false, unique: true
    String :password, null: false
    Integer :password_reset_required, null: false, default: 0
  end

  db.create_table(:pages) do
    String :title, primary_key: true, unique: true
    String :url, null: false, unique: true
    String :language, null: false, default: 'en', check: Sequel.lit("language IN ('en', 'da')")
    DateTime :last_updated
    String :content, null: false, text: true
  end

  db[:pages].insert(
    title: 'Test Page',
    url: 'http://example.com',
    language: 'en',
    last_updated: '2024-01-01',
    content: 'test content'
  )
  
  db.disconnect
end

# Set up test database before loading app
setup_test_db

require_relative '../app'

RSpec.configure do |config|
  config.include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  config.before(:each) do
    clear_cookies
    
    # Reset database for each test
    db = Sequel.sqlite(TEST_DB_PATH)
    db.run('DELETE FROM pages')
    db.run('DELETE FROM users')
    db[:pages].insert(
      title: 'Test Page',
      url: 'http://example.com',
      language: 'en',
      last_updated: '2024-01-01',
      content: 'test content'
    )
    db.disconnect
  end

  config.after(:suite) do
    FileUtils.rm_f(TEST_DB_PATH)
  end
end

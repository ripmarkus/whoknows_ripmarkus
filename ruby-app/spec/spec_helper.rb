# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'
ENV['DATABASE_URL'] ||= 'postgres://whoknows:secret@localhost/whoknows_test'

require 'rack/test'
require 'rspec'

require_relative '../app'

Sequel.extension :migration
Sequel::Migrator.run(DB, File.join(__dir__, '..', 'db', 'migrations'))

def setup_test_db
  DB.run('TRUNCATE users, pages RESTART IDENTITY CASCADE')
  DB[:pages].insert(
    title: 'Test Page',
    url: 'http://example.com',
    language: 'en',
    last_updated: '2024-01-01',
    content: 'test content'
  )
end

setup_test_db

RSpec.configure do |config|
  config.include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  config.before(:each) do
    setup_test_db
  end
end

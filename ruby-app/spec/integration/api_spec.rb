# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'API endpoints' do
  it 'GET /api/search returns JSON results' do
    get '/api/search', query: 'Test'
    expect(last_response.status).to eq(200)
    body = JSON.parse(last_response.body)
    expect(body['results']).to be_an(Array)
    expect(body['results'].length).to eq(1)
  end

  it 'GET /api/search with no match returns empty' do
    get '/api/search', query: 'nonexistent'
    body = JSON.parse(last_response.body)
    expect(body['results']).to be_empty
  end

  it 'POST /api/register succeeds with valid params' do
    post '/api/register', username: 'newuser', email: 'new@test.com', password: 'pass', password2: 'pass'
    expect(last_response.status).to eq(200)
    body = JSON.parse(last_response.body)
    expect(body['message']).to eq('Registration successful')
  end

  it 'POST /api/register fails with missing username' do
    post '/api/register', username: '', email: 'new@test.com', password: 'pass', password2: 'pass'
    expect(last_response.status).to eq(400)
    body = JSON.parse(last_response.body)
    expect(body['error']).to eq('You have to enter a username')
  end

  it 'POST /api/register fails with duplicate username' do
    post '/api/register', username: 'dupe', email: 'a@test.com', password: 'pass', password2: 'pass'
    post '/api/logout'
    post '/api/register', username: 'dupe', email: 'b@test.com', password: 'pass', password2: 'pass'
    expect(last_response.status).to eq(400)
    body = JSON.parse(last_response.body)
    expect(body['error']).to eq('The username already exists')
  end

  it 'POST /api/register fails with duplicate email' do
    post '/api/register', username: 'user1', email: 'same@test.com', password: 'pass', password2: 'pass'
    post '/api/logout'
    post '/api/register', username: 'user2', email: 'same@test.com', password: 'pass', password2: 'pass'
    expect(last_response.status).to eq(400)
    body = JSON.parse(last_response.body)
    expect(body['error']).to eq('The email already exists')
  end

  it 'POST /api/login fails with bad credentials' do
    post '/api/login', username: 'nobody', password: 'wrong'
    expect(last_response.status).to eq(401)
    body = JSON.parse(last_response.body)
    expect(body['error']).to eq('Invalid credentials')
  end

  it 'GET /api/users returns user list' do
    post '/api/register', username: 'listuser', email: 'list@test.com', password: 'pass', password2: 'pass'
    get '/api/users'
    expect(last_response.status).to eq(200)
    body = JSON.parse(last_response.body)
    expect(body).to be_an(Array)
    expect(body.any? { |u| u['username'] == 'listuser' }).to be true
  end

  it 'POST /api/login succeeds after registration' do
    post '/api/register', username: 'logintest', email: 'login@test.com', password: 'pass', password2: 'pass'
    post '/api/logout'
    post '/api/login', username: 'logintest', password: 'pass'
    expect(last_response.status).to eq(200)
    body = JSON.parse(last_response.body)
    expect(body['message']).to eq('Login successful')
  end

  describe 'POST /api/pages' do
    let(:secret) { 'test-secret' }
    let(:valid_page) { { 'title' => 'New Page', 'url' => 'http://new.com', 'content' => 'hello world', 'language' => 'en' } }

    it 'returns 403 with no secret header' do
      post '/api/pages', [valid_page].to_json, 'CONTENT_TYPE' => 'application/json'
      expect(last_response.status).to eq(403)
    end

    it 'returns 403 with wrong secret' do
      header 'X-Crawler-Secret', 'wrong'
      post '/api/pages', [valid_page].to_json, 'CONTENT_TYPE' => 'application/json'
      expect(last_response.status).to eq(403)
    end

    it 'returns 422 when body is not an array or pages object' do
      header 'X-Crawler-Secret', secret
      post '/api/pages', { 'title' => 'x' }.to_json, 'CONTENT_TYPE' => 'application/json'
      expect(last_response.status).to eq(422)
    end

    it 'inserts valid pages and returns count' do
      header 'X-Crawler-Secret', secret
      post '/api/pages', [valid_page].to_json, 'CONTENT_TYPE' => 'application/json'
      expect(last_response.status).to eq(200)
      body = JSON.parse(last_response.body)
      expect(body['inserted']).to eq(1)
    end

    it 'skips pages missing required fields' do
      header 'X-Crawler-Secret', secret
      post '/api/pages', [{ 'url' => 'http://x.com' }].to_json, 'CONTENT_TYPE' => 'application/json'
      body = JSON.parse(last_response.body)
      expect(body['inserted']).to eq(0)
    end

    it 'upserts existing pages by url' do
      header 'X-Crawler-Secret', secret
      post '/api/pages', [valid_page].to_json, 'CONTENT_TYPE' => 'application/json'
      updated = valid_page.merge('content' => 'updated content')
      header 'X-Crawler-Secret', secret
      post '/api/pages', [updated].to_json, 'CONTENT_TYPE' => 'application/json'
      expect(last_response.status).to eq(200)
    end
  end
end

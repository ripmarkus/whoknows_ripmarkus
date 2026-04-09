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
end

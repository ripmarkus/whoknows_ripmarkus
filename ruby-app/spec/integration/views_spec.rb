# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'HTML routes' do
  it 'GET / returns 200' do
    get '/'
    expect(last_response.status).to eq(200)
  end

  it 'GET /about returns 200' do
    get '/about'
    expect(last_response.status).to eq(200)
  end

  it 'GET /login returns 200' do
    get '/login'
    expect(last_response.status).to eq(200)
  end

  it 'GET /register returns 200' do
    get '/register'
    expect(last_response.status).to eq(200)
  end
end

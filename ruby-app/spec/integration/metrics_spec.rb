# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe '/metrics endpoint' do
  before(:all) do
    ENV['MONITORING_IP'] = '127.0.0.1'
  end

  it 'returns 403 when request IP does not match MONITORING_IP' do
    get '/metrics', {}, { 'REMOTE_ADDR' => '10.0.0.1' }
    expect(last_response.status).to eq(403)
  end

  it 'returns 200 with Prometheus text content-type when IP matches' do
    get '/metrics', {}, { 'REMOTE_ADDR' => '127.0.0.1' }
    expect(last_response.status).to eq(200)

    content_type = last_response.headers['Content-Type']
    expect(content_type).to include('text/plain')
    expect(content_type).to include('version=0.0.4')
  end

  it 'returns a body that parses as Prometheus text format' do
    get '/api/search', query: 'test'

    get '/metrics', {}, { 'REMOTE_ADDR' => '127.0.0.1' }
    body = last_response.body

    expect(body).to include('# HELP http_requests_total')
    expect(body).to include('# TYPE http_requests_total counter')
    expect(body).to match(/^http_requests_total\{/)
  end

  it 'labels HTTP metrics by route template, not raw path' do
    get '/api/search', query: 'ignored'

    get '/metrics', {}, { 'REMOTE_ADDR' => '127.0.0.1' }
    body = last_response.body

    expect(body).to match(%r{http_requests_total\{[^}]*path="/api/search"})
    expect(body).not_to include('query=ignored')
  end
end
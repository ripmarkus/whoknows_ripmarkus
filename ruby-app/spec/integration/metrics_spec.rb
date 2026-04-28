# metrics_spec.rb
require 'spec_helper'

RSpec.describe 'Metrics endpoint and instrumentation' do
  def metrics_body
    get '/metrics', {}, { 'REMOTE_ADDR' => '127.0.0.1' }
    expect(last_response.status).to eq(200)
    last_response.body
  end

  def metric_value(body, metric_name, expected_labels = {})
    lines = body.split("\n").select do |line|
      line.start_with?(metric_name)
    end

    matching_line = lines.find do |line|
      expected_labels.all? do |key, value|
        line.include?(%(#{key}="#{value}"))
      end
    end

    return 0.0 unless matching_line

    matching_line.split(' ').last.to_f
  end

  it 'blocks access to /metrics from non-monitoring IPs' do
    get '/metrics', {}, { 'REMOTE_ADDR' => '10.0.0.55' }
    expect(last_response.status).to eq(403)
  end

  it 'allows access to /metrics from monitoring IP' do
    get '/metrics', {}, { 'REMOTE_ADDR' => '127.0.0.1' }

    expect(last_response.status).to eq(200)
    expect(last_response.headers['Content-Type']).to include('text/plain')
    expect(last_response.body).to include('# TYPE')
  end

  it 'uses route templates as path labels instead of raw query strings' do
    get '/api/search', { query: 'hello' }
    body = metrics_body

    expect(body).to include('http_requests_total')
    expect(body).to include('path="/api/search"')
    expect(body).not_to include('/api/search?query=hello')
  end

  it 'increments search query counter when searching' do
    before_body = metrics_body
    before_value = metric_value(
      before_body,
      'search_queries_total',
      language: 'latin',
      hit: 'hit'
    )

    get '/api/search', { query: 'test' }

    after_body = metrics_body
    after_value = metric_value(
      after_body,
      'search_queries_total',
      language: 'latin',
      hit: 'hit'
    )

    expect(after_value).to be > before_value
  end

  it 'increments login failure metric on failed login' do
    before_body = metrics_body
    before_value = metric_value(
      before_body,
      'login_attempts_total',
      result: 'failure'
    )

    post '/login',
         { email: 'nobody@example.com', password: 'wrong-password' }.to_json,
         { 'CONTENT_TYPE' => 'application/json' }

    expect(last_response.status).to eq(401)

    after_body = metrics_body
    after_value = metric_value(
      after_body,
      'login_attempts_total',
      result: 'failure'
    )

    expect(after_value).to be > before_value
  end

  it 'increments registration failure metric on invalid registration' do
    before_body = metrics_body
    before_value = metric_value(
      before_body,
      'registrations_total',
      result: 'failure'
    )

    post '/register',
         { email: 'bad-email', password: '123' }.to_json,
         { 'CONTENT_TYPE' => 'application/json' }

    expect(last_response.status).to eq(422)

    after_body = metrics_body
    after_value = metric_value(
      after_body,
      'registrations_total',
      result: 'failure'
    )

    expect(after_value).to be > before_value
  end

  it 'increments weather outbound metrics with phase labels' do
    allow_any_instance_of(Object).to receive(:weather_api_key).and_return('fake-key')

    geocoding_response = instance_double(Net::HTTPSuccess, code: '200', body: '[{"lat":55.6761,"lon":12.5683}]')
    weather_response = instance_double(Net::HTTPSuccess, code: '200', body: '{"main":{"temp":17.2}}')

    allow(Net::HTTP).to receive(:get_response).and_return(geocoding_response, weather_response)

    before_body = metrics_body
    before_geo = metric_value(
      before_body,
      'weather_api_requests_total',
      phase: 'geocoding',
      status_code: '200'
    )
    before_weather = metric_value(
      before_body,
      'weather_api_requests_total',
      phase: 'weather',
      status_code: '200'
    )

    get '/api/weather', { city: 'Copenhagen' }
    expect(last_response.status).to eq(200)

    after_body = metrics_body
    after_geo = metric_value(
      after_body,
      'weather_api_requests_total',
      phase: 'geocoding',
      status_code: '200'
    )
    after_weather = metric_value(
      after_body,
      'weather_api_requests_total',
      phase: 'weather',
      status_code: '200'
    )

    expect(after_geo).to be > before_geo
    expect(after_weather).to be > before_weather
  end

  it 'does not label skipped weather endpoint as normal inbound http metric if disabled in after hook' do
    allow_any_instance_of(Object).to receive(:weather_api_key).and_return('fake-key')

    geocoding_response = instance_double(Net::HTTPSuccess, code: '200', body: '[{"lat":55.6761,"lon":12.5683}]')
    weather_response = instance_double(Net::HTTPSuccess, code: '200', body: '{"main":{"temp":17.2}}')
    allow(Net::HTTP).to receive(:get_response).and_return(geocoding_response, weather_response)

    before_body = metrics_body
    before_http = metric_value(
      before_body,
      'http_requests_total',
      method: 'GET',
      path: '/api/weather',
      status_code: '200'
    )

    get '/api/weather', { city: 'Copenhagen' }
    expect(last_response.status).to eq(200)

    after_body = metrics_body
    after_http = metric_value(
      after_body,
      'http_requests_total',
      method: 'GET',
      path: '/api/weather',
      status_code: '200'
    )

    expect(after_http).to eq(before_http)
  end
end
# frozen_string_literal: true

get '/health' do
  json status: 'ok'
end

get '/metrics' do
  content_type 'text/plain; version=0.0.4; charset=utf-8'
  Prometheus::Client::Formats::Text.marshal(PROM_REGISTRY)
end

get '/api/docs' do
  spec_url = '/api/docs/openapi.yaml'
  erb :openapi, locals: { spec_url: spec_url }, layout: false
end

get '/api/docs/openapi.yaml' do
  content_type 'text/yaml'
  send_file File.join(settings.root, 'OpenAPI', 'OpenAPI.yaml')
end

get '/api/users' do
  content_type :json
  DB[:users].select(:id, :username, :email).all.to_json
end

get '/api/search' do
  query = params['query'].to_s.strip
  language = params['language'].to_s.strip
  language = 'en' if language.empty?

  started_at = monotonic_now

  dataset = DB[:pages]
  dataset = dataset.where(language: language) unless language.empty?
  dataset = apply_search_filters(dataset, query, language) unless query.empty?
  results = dataset.select(:title, :url, :language, :last_updated, :content).all
  hit = results.empty? ? 'miss' : 'hit'
  LOGGER.info("[SEARCH] query=#{query.inspect} language=#{language.inspect} hit=#{hit} results=#{results.size}")
  duration = monotonic_now - started_at

  SEARCH_QUERIES_TOTAL.increment(labels: { language: language_label_for(query), hit: hit })
  SEARCH_DURATION_SECONDS.observe(duration, labels: { language: language_label_for(query), hit: hit })
  SEARCH_KEYWORD_TOTAL.increment(labels: { hit: hit }) unless query.to_s.strip.empty?

  json results: results
end

post '/api/login' do
  payload = request_payload
  identifier = payload_value(payload, :email).to_s.strip
  identifier = payload_value(payload, :username).to_s.strip if identifier.empty?
  password = payload_value(payload, :password).to_s

  user = find_user_for_login(identifier)

  if user && password_matches?(user[:password], password)
    LOGIN_ATTEMPTS_TOTAL.increment(labels: { result: 'success' })
    session[:user_id] = user[:id]
    session[:username] = user[:username] if user[:username]
    status 200
    json message: 'Login successful', username: user[:username]
  else
    LOGIN_ATTEMPTS_TOTAL.increment(labels: { result: 'failure' })
    halt 401, json(error: 'Invalid credentials')
  end
end

post '/api/register' do
  payload = request_payload
  error = validate_registration_fields(payload)

  email = payload_value(payload, :email).to_s.strip
  username = payload_value(payload, :username).to_s.strip

  error = 'The username already exists' if error.nil? && DB[:users].where(username: username).first
  error = 'The email already exists' if error.nil? && DB[:users].where(email: email).first

  if error
    REGISTRATIONS_TOTAL.increment(labels: { result: 'failure' })
    halt 400, json(error: error)
  end

  insert_data = {
    email: email,
    password: hash_password(payload['password'].to_s)
  }
  insert_data[:username] = username unless username.empty?

  user_id = DB[:users].insert(insert_data)

  REGISTRATIONS_TOTAL.increment(labels: { result: 'success' })
  session[:user_id] = user_id
  session[:username] = username unless username.empty?

  status 200
  json message: 'Registration successful', username: username
end

post '/api/logout' do
  session.delete(:user_id)
  session.delete(:username)
  json message: 'logout ok'
end

post '/api/change-password' do
  halt 401, json(error: 'not_authenticated') unless session[:user_id]

  payload = request_payload
  old_password = payload['old_password'].to_s
  old_password = payload['current_password'].to_s if old_password.empty?
  new_password = payload['new_password'].to_s

  user = DB[:users].where(id: session[:user_id]).first

  unless user && password_matches?(user[:password], old_password)
    PASSWORD_CHANGES_TOTAL.increment(labels: { result: 'failure' })
    halt 401, json(error: 'invalid_credentials')
  end

  if new_password.length < 8
    PASSWORD_CHANGES_TOTAL.increment(labels: { result: 'failure' })
    halt 422, json(error: 'new_password_too_short')
  end

  DB[:users].where(id: session[:user_id]).update(
    password: hash_password(new_password),
    password_reset_required: 0
  )

  PASSWORD_CHANGES_TOTAL.increment(labels: { result: 'success' })
  json message: 'password changed'
end

post '/api/pages' do
  secret = ENV['CRAWLER_SECRET'].to_s.strip
  halt 403, json(error: 'forbidden') if secret.empty? || request.env['HTTP_X_CRAWLER_SECRET'] != secret

  payload = request_payload
  pages = if payload.is_a?(Array)
    payload
  elsif payload.is_a?(Hash) && payload['pages'].is_a?(Array)
    payload['pages']
  else
    halt 422, json(error: 'invalid request: expected array or object with pages array')
  end

  inserted = 0
  pages.each do |page|
    next unless page.is_a?(Hash) && page['url'] && page['content'] && page['title']
    next if page['content'].to_s.bytesize > 1_048_576
    lang = %w[en da].include?(page['language']) ? page['language'] : 'en'
    DB[:pages].insert_conflict(
      target: :url,
      update: { title: page['title'], content: page['content'], language: lang, last_updated: Time.now }
    ).insert(
      title: page['title'], url: page['url'], content: page['content'],
      language: lang, last_updated: Time.now
    )
    inserted += 1
  end

  LOGGER.info("[CRAWLER] inserted=#{inserted} total=#{pages.size}")
  json inserted: inserted
end

get '/api/weather' do
  city = params['city'].to_s.strip
  country = params['country'].to_s.strip

  halt 422, json(error: 'city is required') if city.empty?

  payload = get_weather_for(city, country)
  json payload
end

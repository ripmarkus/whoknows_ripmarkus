# frozen_string_literal: true

get '/' do
  query = params[:query]
  language = params[:language] || 'en'

  if query.nil?
    erb :home
  else
    started_at = monotonic_now
    dataset = DB[:pages]
    dataset = dataset.where(language: language)
    dataset = apply_search_filters(dataset, query, language) unless query.to_s.strip.empty?
    results = dataset.select(:title, :url, :language, :last_updated, :content).all
    hit = results.empty? ? 'miss' : 'hit'
    LOGGER.info("[SEARCH] query=#{query.to_s.strip.inspect} language=#{language.inspect} hit=#{hit} results=#{results.size}")
    duration = monotonic_now - started_at

    SEARCH_QUERIES_TOTAL.increment(labels: { language: language_label_for(query), hit: hit })
    SEARCH_DURATION_SECONDS.observe(duration, labels: { language: language_label_for(query), hit: hit })

    erb :search, locals: { search_results: results, query: query }
  end
end

get '/about' do
  erb :about
end

get '/login' do
  erb :login, locals: { error: nil }
end

post '/login' do
  payload = request_payload
  identifier = payload_value(payload, :email).to_s.strip
  identifier = payload_value(payload, :username).to_s.strip if identifier.empty?
  password = payload_value(payload, :password).to_s

  user = find_user_for_login(identifier)

  if user && password_matches?(user[:password], password)
    LOGIN_ATTEMPTS_TOTAL.increment(labels: { result: 'success' })
    session[:user_id] = user[:id]
    session[:username] = user[:username] if user[:username]

    if request.media_type.to_s.include?('application/json')
      status 200
      json message: 'login ok'
    else
      redirect '/'
    end
  else
    LOGIN_ATTEMPTS_TOTAL.increment(labels: { result: 'failure' })

    if request.media_type.to_s.include?('application/json')
      halt 401, json(error: 'Invalid credentials')
    else
      status 401
      erb :login, locals: { error: 'Invalid credentials' }
    end
  end
end

get '/register' do
  erb :register, locals: { error: nil }
end

post '/register' do
  payload = request_payload
  error = validate_registration_fields(payload)

  email = payload_value(payload, :email).to_s.strip
  username = payload_value(payload, :username).to_s.strip

  error = 'The username already exists' if error.nil? && !username.empty? && DB[:users].where(username: username).first
  error = 'The email already exists' if error.nil? && !email.empty? && DB[:users].where(email: email).first

  if error
    REGISTRATIONS_TOTAL.increment(labels: { result: 'failure' })

    if request.media_type.to_s.include?('application/json')
      halt 422, json(error: error)
    else
      status 422
      return erb :register, locals: { error: error }
    end
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

  if request.media_type.to_s.include?('application/json')
    status 201
    json message: 'registered'
  else
    redirect '/'
  end
end

get '/change-password' do
  redirect '/login' unless session[:user_id]
  erb :change_password, locals: { error: nil }
end

post '/change-password' do
  redirect '/login' unless session[:user_id]

  user = DB[:users].where(id: session[:user_id]).first
  halt 403 unless user

  unless password_matches?(user[:password], params[:current_password].to_s)
    PASSWORD_CHANGES_TOTAL.increment(labels: { result: 'failure' })
    return erb :change_password, locals: { error: 'Current password is incorrect' }
  end

  if params[:new_password].to_s.length < 8
    PASSWORD_CHANGES_TOTAL.increment(labels: { result: 'failure' })
    return erb :change_password, locals: { error: 'New password must be at least 8 characters' }
  end

  if params[:new_password].to_s != params[:new_password2].to_s
    PASSWORD_CHANGES_TOTAL.increment(labels: { result: 'failure' })
    return erb :change_password, locals: { error: 'New passwords do not match' }
  end

  DB[:users].where(id: session[:user_id]).update(
    password: hash_password(params[:new_password].to_s),
    password_reset_required: 0
  )

  PASSWORD_CHANGES_TOTAL.increment(labels: { result: 'success' })
  redirect '/'
end

post '/logout' do
  session.delete(:user_id)
  session.delete(:username)
  session[:flash] = 'You were logged out'
  redirect '/'
end

get '/weather' do
  city = params.fetch(:city, 'København').to_s.strip
  country = params.fetch(:country, '').to_s.strip

  payload = get_weather_for(city, country)
  @loc = payload['location']
  @w = payload['weather']
  erb :weather
end

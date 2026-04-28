# frozen_string_literal: true

require 'sinatra'
require 'sequel'
require 'json'
require 'bcrypt'
require 'net/http'
require 'uri'
require 'logger'
require 'fileutils'
require 'ipaddr'
require 'dotenv/load'
require 'prometheus/client'
require 'prometheus/client/formats/text'

require_relative 'helpers/helpers'

configure do
  enable :sessions
  set :show_exceptions, false
  set :protection, except: :host_authorization

  FileUtils.mkdir_p('logs')
  LOGGER = Logger.new('logs/app.log')

  Dir.chdir(__dir__) if ENV['RACK_ENV'] == 'test'

  DB = Sequel.connect(ENV.fetch('DATABASE_URL'))

  PROM_REGISTRY = Prometheus::Client.registry
end

require_relative 'metrics/metrics'
require_relative 'auth/auth'
require_relative 'search/search'
require_relative 'weather/weather'

helpers do
  include Rack::Utils
  alias_method :h, :escape_html
  include AppHelpers
  include MetricsHelpers
  include AuthHelpers
  include SearchHelpers
  include WeatherHelpers
end

before do
  env['metrics.started_at'] = monotonic_now

  if session[:user_id] && !['/change-password', '/logout', '/api/logout', '/api/change-password'].include?(request.path_info)
    user = DB[:users].where(id: session[:user_id]).select(:password_reset_required).first
    redirect '/change-password' if user && user[:password_reset_required] == 1 && !request.path_info.start_with?('/api/')
  end
end

after do
  next if skip_http_metrics?(env)

  status_code = response.status.to_i.to_s
  duration = monotonic_now - env.fetch('metrics.started_at', monotonic_now)

  labels = {
    method: request.request_method,
    path: metrics_path_label(env),
    status_code: status_code
  }

  HTTP_REQUESTS_TOTAL.increment(labels: labels)
  HTTP_REQUEST_DURATION_SECONDS.observe(duration, labels: labels)
end

error do
  err = env['sinatra.error']
  path = metrics_path_label(env)

  unless request.path_info == '/metrics'
    HTTP_REQUEST_ERRORS_TOTAL.increment(
      labels: {
        method: request.request_method,
        path: path,
        error_class: err.class.name
      }
    )
  end

  LOGGER.error("#{err.class}: #{err.message}") if err

  if json_request?
    status 500
    json error: 'internal_server_error'
  else
    content_type 'text/plain'
    status 500
    'Internal Server Error'
  end
end

require_relative 'routes/html_routes'
require_relative 'routes/api_routes'

# frozen_string_literal: true

module WeatherHelpers
  def weather_api_key
    ENV['OPENWEATHER_API_KEY'].to_s.strip
  end

  def safe_json_parse(body, context:)
    JSON.parse(body)
  rescue JSON::ParserError => e
    LOGGER.warn("[#{context}] JSON parse error: #{e.class}: #{e.message}")
    { 'raw' => body }
  end

  def http_get_json(uri_string, phase:)
    uri = URI(uri_string)
    started_at = monotonic_now

    response = Net::HTTP.get_response(uri)
    status_code = safe_status_code(response)
    duration = monotonic_now - started_at

    WEATHER_API_REQUESTS_TOTAL.increment(
      labels: { phase: phase, status_code: status_code }
    )

    WEATHER_API_DURATION_SECONDS.observe(
      duration,
      labels: { phase: phase, status_code: status_code }
    )

    safe_json_parse(response.body.to_s, context: "openweather:#{phase}")
  rescue StandardError => e
    WEATHER_API_ERRORS_TOTAL.increment(
      labels: { phase: phase, error_class: e.class.name }
    )
    raise
  end

  def get_weather_for(city, country = nil)
    location_query =
      if country.to_s.strip.empty?
        city
      else
        "#{city},#{country}"
      end

    geocoding_url = "https://api.openweathermap.org/geo/1.0/direct?q=#{URI.encode_www_form_component(location_query)}&limit=1&appid=#{weather_api_key}"
    geocoding_data = http_get_json(geocoding_url, phase: 'geocoding')

    first_match = geocoding_data.is_a?(Array) ? geocoding_data.first : nil
    raise Sinatra::NotFound, 'City not found' unless first_match

    lat = first_match.fetch('lat')
    lon = first_match.fetch('lon')

    weather_url = "https://api.openweathermap.org/data/2.5/weather?lat=#{lat}&lon=#{lon}&appid=#{weather_api_key}&units=metric&lang=da"
    weather_data = http_get_json(weather_url, phase: 'weather')

    {
      'location' => first_match,
      'weather' => weather_data
    }
  end
end

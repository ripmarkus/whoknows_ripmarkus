# frozen_string_literal: true

module AppHelpers
  def payload_value(payload, key)
    payload[key.to_s] || payload[key.to_sym]
  end

  def json(payload = nil, status_code: nil, **kwargs)
    response_payload = payload || kwargs
    content_type :json
    status status_code if status_code
    response_payload.to_json
  end

  def monotonic_now
    Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end

  def parsed_json_body
    body = request.body.read.to_s
    request.body.rewind
    JSON.parse(body)
  rescue JSON::ParserError
    {}
  end

  def request_payload
    if request.media_type.to_s.include?('application/json')
      parsed_json_body
    else
      params
    end
  end

  def safe_status_code(response)
    if response.respond_to?(:code) && !response.code.to_s.strip.empty?
      response.code.to_s
    else
      'unknown'
    end
  end

  def json_request?
    request.path_info.start_with?('/api/') || request.media_type.to_s.include?('application/json')
  end
end

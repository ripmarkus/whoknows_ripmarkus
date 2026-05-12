# frozen_string_literal: true

module AuthHelpers
  def hash_password(password)
    BCrypt::Password.create(password)
  end

  def password_matches?(password_hash, plaintext_password)
    BCrypt::Password.new(password_hash) == plaintext_password
  rescue BCrypt::Errors::InvalidHash
    false
  end

  def validate_registration_fields(payload)
    username = payload_value(payload, :username).to_s
    email = payload_value(payload, :email).to_s
    password = payload_value(payload, :password).to_s
    password2 = payload_value(payload, :password2).to_s

    return 'You have to enter a username' if username.strip.empty?
    return 'Valid email address needed' if email.strip.empty? || !email.include?('@')
    return 'You have to enter a password' if password.strip.empty?
    return 'The two passwords do not match' if password != password2

    nil
  end

  def find_user_for_login(identifier)
    DB[:users].where(email: identifier).first ||
      DB[:users].where(username: identifier).first
  end

  def allowed_ip?(request_ip, allowed)
    return false if allowed.to_s.strip.empty?

    IPAddr.new(allowed).include?(request_ip)
  rescue IPAddr::InvalidAddressError
    request_ip == allowed
  end

  def current_request_ip
    request.ip
  end
end

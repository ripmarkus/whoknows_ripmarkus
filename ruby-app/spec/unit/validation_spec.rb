# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'validate_registration_fields' do
  it 'returns error when username is missing' do
    result = validate_registration_fields({ username: '', email: 'a@b.com', password: 'pw', password2: 'pw' })
    expect(result).to eq('You have to enter a username')
  end

  it 'returns error when email has no @' do
    result = validate_registration_fields({ username: 'user', email: 'invalid', password: 'pw', password2: 'pw' })
    expect(result).to eq('Valid email address needed')
  end

  it 'returns error when password is blank' do
    result = validate_registration_fields({ username: 'user', email: 'a@b.com', password: '  ', password2: '  ' })
    expect(result).to eq('You have to enter a password')
  end

  it 'returns error when passwords do not match' do
    result = validate_registration_fields({ username: 'user', email: 'a@b.com', password: 'pw1', password2: 'pw2' })
    expect(result).to eq('The two passwords do not match')
  end

  it 'returns nil when all fields are valid' do
    result = validate_registration_fields({ username: 'user', email: 'a@b.com', password: 'pw', password2: 'pw' })
    expect(result).to be_nil
  end
end

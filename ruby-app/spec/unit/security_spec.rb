# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'password hashing' do
  it 'hash_password returns a BCrypt hash' do
    hash = hash_password('secret')
    expect(hash).to be_a(BCrypt::Password)
  end

  it 'password_matches? returns true for correct password' do
    hash = hash_password('secret')
    expect(password_matches?(hash.to_s, 'secret')).to be true
  end

  it 'password_matches? returns false for wrong password' do
    hash = hash_password('secret')
    expect(password_matches?(hash.to_s, 'wrong')).to be false
  end
end

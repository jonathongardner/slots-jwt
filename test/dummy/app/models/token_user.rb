# frozen_string_literal: true

class TokenUser < ApplicationRecord
  include Slots::JWT::GenericMethods, Slots::JWT::Tokens

  def authenticate(password)
    password == self.class.pass ? self : false
  end

  def self.pass
    'token_password'
  end
end

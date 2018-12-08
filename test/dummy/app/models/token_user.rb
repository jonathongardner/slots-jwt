# frozen_string_literal: true

class TokenUser < ApplicationRecord
  slots :database_authentication

  def authenticate(password)
    password == self.class.pass ? self : false
  end

  def self.pass
    'token_password'
  end
end

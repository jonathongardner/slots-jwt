# frozen_string_literal: true

class TokenUser < ApplicationRecord
  include Slots::GenericMethods, Slots::Tokens

  def authenticate(password)
    password == self.class.pass ? self : false
  end

  def self.pass
    'token_password'
  end
end

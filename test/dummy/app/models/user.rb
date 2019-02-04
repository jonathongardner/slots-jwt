# frozen_string_literal: true

class User < ApplicationRecord
  slots :database_authentication

  def self.pass
    'a_crazy_password'
  end

  reject_new_token do
    self.username == 'weirdusername'
  end
end

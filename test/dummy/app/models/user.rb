# frozen_string_literal: true

class User < ApplicationRecord
  slots :database_authentication, :confirmable

  def self.pass
    'a_crazy_password'
  end
end

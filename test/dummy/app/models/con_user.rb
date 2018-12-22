# frozen_string_literal: true

class ConUser < ApplicationRecord
  slots :confirmable

  def authenticate(password)
    password == self.class.pass ? self : false
  end

  def self.pass
    'con_password'
  end
end

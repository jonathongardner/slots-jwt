# frozen_string_literal: true

class GenericUser < ApplicationRecord
  include Slots::GenericMethods

  def authenticate(password)
    password == self.class.pass ? self : false
  end

  def slots?(_)
    false
  end

  def self.pass
    'not_db_password'
  end
end

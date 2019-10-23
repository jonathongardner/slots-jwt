# frozen_string_literal: true

class GenericUser < ApplicationRecord
  include Slots::JWT::GenericMethods

  reject_new_token do
    username == 'badUsername@thisdontwork'
  end

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

# frozen_string_literal: true

class AppUser < ApplicationRecord
  slots :approvable

  def authenticate(password)
    password == self.class.pass ? self : false
  end

  def self.pass
    'app_password'
  end

  def can_approve?(_)
    self.email ==  'AnotherApprovedUserEmail@somewhere.com'
  end
end

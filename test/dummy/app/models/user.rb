# frozen_string_literal: true

class User < ApplicationRecord
  slots :database_authentication, :approvable, :confirmable

  def self.pass
    'a_crazy_password'
  end

  def can_approve?(_)
    self.username == 'someusername'
  end
end

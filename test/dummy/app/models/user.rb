# frozen_string_literal: true

class User < ApplicationRecord
  slots :database_authentication, :approvable, :confirmable

  def self.pass
    'a_crazy_password'
  end

  def can_approve?(_)
    self.username == 'someusername'
  end

  def send_confirmation_email
    self.class.email_count = self.class.email_count + 1
  end

  def self.email_count
    @email_count
  end

  def self.email_count=(v)
    @email_count = v
  end
end

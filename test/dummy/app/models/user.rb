# frozen_string_literal: true

class User < ApplicationRecord
  slots :database_authentication

  def self.pass
    'a_crazy_password'
  end

  reject_new_token do
    self.username == 'weirdusername'
  end

  failed_login do
    next if new_record? || self.failed_attempts >= 5
    self.failed_attempts += 1
    # skip callback
    update_columns(failed_attempts: self.failed_attempts)
  end

  successful_login do
    update_columns(failed_attempts: 0) if self.failed_attempts > 0
  end
end

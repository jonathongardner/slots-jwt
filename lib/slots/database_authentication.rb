# frozen_string_literal: true

module DatabaseAuthentication
  extend ActiveSupport::Concern

  included do
    has_secure_password
  end

  def as_json(*)
    super.except('password_digest')
  end

  module ClassMethods
  end
end

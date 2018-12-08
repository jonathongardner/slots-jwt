# frozen_string_literal: true

module Tokens
  extend ActiveSupport::Concern

  included do
  end

  def jwt_identifier
    send(self.class.jwt_identifier_column)
  end

  def create_token
    @slots_jwt = Slots::Slokens.encode(jwt_identifier)
    current_token
  end

  def current_token
    @slots_jwt&.token
  end

  def jwt
    @slots_jwt
  end

  def valid_token!(slots_jwt)
    @slots_jwt = slots_jwt
    add_logged_in(:token)
    self
  end

  module ClassMethods
    def valid_token_and_user?(token)
      slots_jwt = valid_token?(token)
      return nil unless slots_jwt
      user = self.find_by(jwt_identifier_column => slots_jwt.identifier)
      user&.valid_token!(slots_jwt)
    end
    def valid_token?(token)
      begin
        return Slots::Slokens.decode(token)
      rescue JWT::ExpiredSignature
        return false
      rescue JWT::InvalidIatError, JWT::VerificationError, JWT::DecodeError, Slots::InvalidPayload, Slots::InvalidSecret
        return false
      end
    end

    def jwt_identifier_column
      Slots.configuration.logins.keys.first
    end
  end
end

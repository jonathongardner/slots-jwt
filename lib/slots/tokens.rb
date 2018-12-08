# frozen_string_literal: true

module Tokens
  extend ActiveSupport::Concern

  included do
  end

  def jwt_identifier
    send(self.class.jwt_identifier_column)
  end

  def create_token
    @slot_jwt = Slots::JWT.encode(jwt_identifier)
  end

  def jwt
    @slot_jwt
  end

  module ClassMethods
    def valid_token?(token)
      begin
        @slot_jwt = Slots::Slokens.decode(token)
        add_logged_in(:token)
        return true
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

# frozen_string_literal: true

module Tokens
  extend ActiveSupport::Concern

  included do
  end

  def jwt_identifier
    send(self.class.jwt_identifier_column)
  end

  def create_token(session)
    options = {**extra_payload}
    if session
      @new_session = self.sessions.new(jwt_iat: 0)
      # Session should never be invalid since its all programmed
      raise 'Session not valid' unless @new_session.valid?
      options.update(session: @new_session.session)
    end
    @slots_jwt = Slots::Slokens.encode(jwt_identifier, options)
    if session
      @new_session.jwt_iat = @slots_jwt.iat
      @new_session.save!
    end
    token
  end

  def extra_payload
    @extra_payload || {}
  end

  def token
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
      valid_user?(valid_token?(token))
    end
    def valid_user?(slots_jwt)
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

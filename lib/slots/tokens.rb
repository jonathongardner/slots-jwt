# frozen_string_literal: true

module Tokens
  extend ActiveSupport::Concern

  included do
    @extra_expected_keys = []
  end

  def jwt_identifier
    send(self.class.jwt_identifier_column)
  end

  def create_token(session)
    options = {**extra_payload}
    if session && Slots.configuration.session_lifetime
      @new_session = self.sessions.new(jwt_iat: 0)
      # Session should never be invalid since its all programmed
      raise 'Session not valid' unless @new_session.valid?
      options.update(session: @new_session.session)
    end
    @slots_jwt = Slots::Slokens.encode(jwt_identifier, options)
    if @new_session
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
    def extra_expected_keys
      @extra_expected_keys || []
    end
    def add_extra_expected_keys(*keys)
      (@extra_expected_keys ||= []).concat(keys)
    end
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
        sloken_jws = Slots::Slokens.to_decode(token)
        sloken_jws.decode
        return sloken_jws
      rescue JWT::ExpiredSignature
        return false
      rescue JWT::InvalidIatError, JWT::VerificationError, JWT::DecodeError, Slots::InvalidPayload, Slots::InvalidSecret
        return false
      end
      false
    end
    def valid_token_or_session?(token)
      begin
        sloken_jws = Slots::Slokens.to_decode(token)
        begin
          sloken_jws.decode
        rescue JWT::ExpiredSignature
          return false unless sloken_jws.session && Slots.configuration.session_lifetime
          user = self.find_by(jwt_identifier_column => sloken_jws.identifier)
          return false unless user
          session = user.sessions.matches_jwt(sloken_jws)
          return false unless session
          sloken_jws.update_token
          session.update!(jwt_iat: sloken_jws.iat)
        end
      rescue JWT::InvalidIatError, JWT::VerificationError, JWT::DecodeError, Slots::InvalidPayload, Slots::InvalidSecret
        return false
      end
      sloken_jws
    end

    def jwt_identifier_column
      Slots.configuration.logins.keys.first
    end
  end
end

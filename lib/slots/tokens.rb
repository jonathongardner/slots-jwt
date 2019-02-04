# frozen_string_literal: true

module Slots
  module Tokens
    extend ActiveSupport::Concern

    included do
    end

    def jwt_identifier
      send(self.class.jwt_identifier_column)
    end

    def create_token(have_session)
      options = {**extra_payload}
      session = ''
      if have_session && Slots.configuration.session_lifetime
        @new_session = self.sessions.new(jwt_iat: 0)
        # Session should never be invalid since its all programmed
        raise 'Session not valid' unless @new_session.valid?
        session = @new_session.session
      end
      @slots_jwt = Slots::Slokens.encode(self, session, options)
      if @new_session
        @new_session.jwt_iat = @slots_jwt.iat
        @new_session.save!
      end
      @new_token = true
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
    def set_token!(slots_jwt)
      @slots_jwt = slots_jwt
      self
    end

    def update_session
      return false unless allowed_new_token?
      session = self.sessions.matches_jwt(jwt)
      return false unless session
      old_iat = jwt.iat
      jwt.update_token
      if session.jwt_iat == old_iat
        # if old_iat == previous_jwt_iat dont update and return token
        session.update(previous_jwt_iat: old_iat, jwt_iat: jwt.iat)
        @new_token = true
      end
    end

    def new_token?
      @new_token
    end

    def valid_in_database?
      begin
        jwt_identifier_was = self.jwt_identifier
        self.reload
        return false if jwt_identifier_was != self.jwt_identifier
      rescue ActiveRecord::RecordNotFound
        return false
      end
      true
    end

    module ClassMethods
      def from_sloken(slots_jwt)
        self.new(slots_jwt.authentication_model_values).set_token!(slots_jwt)
      end

      def jwt_identifier_column
        Slots.configuration.logins.keys.first
      end
    end
  end
end

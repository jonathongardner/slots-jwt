# frozen_string_literal: true

module Slots
  module Tokens
    extend ActiveSupport::Concern

    included do
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
      @slots_jwt = Slots::Slokens.encode(self, options)
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
    def set_token!(slots_jwt)
      @slots_jwt = slots_jwt
      self
    end

    def update_session
      session = self.sessions.matches_jwt(jwt)
      return false unless session
      jwt.update_token
      session.update(jwt_iat: jwt.iat)
    end

    def valid_in_database?
      begin
        jwt_identifier_was = self.jwt_identifier
        self.reload
        return false if jwt_identifier_was != self.jwt_identifier
      rescue ActiveRecord::RecordNotFound
        return false
      end
      add_logged_in(:token)
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

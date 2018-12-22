# frozen_string_literal: true

module Slots
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
      def valid_user?(slots_jwt)
        slots_jwt.valid!
        user = self.find_by_sloken(slots_jwt)
        user&.valid_token!(slots_jwt)
      end

      def find_by_sloken(slots_jwt)
        self.find_by(jwt_identifier_column => slots_jwt.identifier)
      end

      def jwt_identifier_column
        Slots.configuration.logins.keys.first
      end
    end
  end
end

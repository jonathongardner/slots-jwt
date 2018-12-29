# frozen_string_literal: true

module Slots
  module AuthenticationHelper
    extend ActiveSupport::Concern

    included do
      include ActionController::HttpAuthentication::Token::ControllerMethods
    end

    def jw_token(session: false)
      return @_jw_token if @_jw_token&.valid!
      @_jw_token = Slots::Slokens.decode(authenticate_with_http_token { |t, _| t })
      if @_jw_token.expired?
        return false unless @_jw_token.session && Slots.configuration.session_lifetime
        user = Slots.configuration.authentication_model.from_sloken(@_jw_token)
        return false unless user&.valid_in_database?
        session = user.sessions.matches_jwt(@_jw_token)
        return false unless session
        @_jw_token.update_token
        session.update!(jwt_iat: @_jw_token.iat)
      end
      @_jw_token.valid!
    end
    def current_user
      return @_current_user if instance_variable_defined?(:@_current_user)
      @_current_user = Slots.configuration.authentication_model.from_sloken(jw_token)
    end
    def load_user
      current_user&.valid_in_database?
    end

    def require_valid_user(session: false)
      jw_token(session: session)
      raise Slots::InvalidToken unless current_user
    end
    def require_valid_loaded_user(session: false)
      jw_token(session: session)
      # Load user will make sure it is in the database and valid in the database
      raise Slots::InvalidToken, "User doesnt exist" unless load_user
      raise Slots::InvalidToken unless current_user&.valid_user?
    end

    module ClassMethods
      def require_login!(load_user: false, **options)
        before_action :require_valid_user, **options unless load_user
        before_action :require_valid_loaded_user, **options if load_user
      end

      def catch_invalid_token(response: {errors: {authentication: ['invalid or missing token']}}, status: :unauthorized)
        rescue_from Slots::InvalidToken do |exception|
          render json: response, status: status
        end
      end

      def ignore_login!(**options)
        skip_before_action :require_valid_user, **options
      end
    end
  end
end

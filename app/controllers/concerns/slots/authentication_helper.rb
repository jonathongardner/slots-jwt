# frozen_string_literal: true

module Slots
  module AuthenticationHelper
    extend ActiveSupport::Concern

    included do
      include ActionController::HttpAuthentication::Token::ControllerMethods
    end

    def current_user
      return @_current_user if instance_variable_defined?(:@_current_user)
      @_current_user = Slots.configuration.authentication_model.valid_user?(jw_token)
    end
    def jw_token(session: false)
      return @_jw_token if @_jw_token&.valid!
      @_jw_token = Slots::Slokens.decode(authenticate_with_http_token { |t, _| t })
      if @_jw_token.expired?
        return false unless @_jw_token.session && Slots.configuration.session_lifetime
        user = Slots.configuration.authentication_model.find_by_sloken(@_jw_token)
        return false unless user
        session = user.sessions.matches_jwt(@_jw_token)
        return false unless session
        @_jw_token.update_token
        session.update!(jwt_iat: @_jw_token.iat)
      end
      @_jw_token.valid!
    end

    def require_valid_token(session: false)
      jw_token(session: session)
    end
    def require_valid_user
      raise Slots::InvalidToken unless current_user
    end

    module ClassMethods
      def require_login!(valid_user: false, **options)
        before_action :require_valid_token, **options
        before_action :require_valid_user, **options if valid_user
      end

      def catch_invalid_token(response: {errors: {authentication: ['invalid or missing token']}}, status: :unauthorized)
        rescue_from Slots::InvalidToken do |exception|
          render json: response, status: status
        end
      end

      def ignore_login!(**options)
        skip_before_action :require_valid_token, **options
      end
    end
  end
end

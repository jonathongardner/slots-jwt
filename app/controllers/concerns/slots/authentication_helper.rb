# frozen_string_literal: true

module Slots
  module AuthenticationHelper
    extend ActiveSupport::Concern

    included do
    end

    def current_user
      return @_current_user if instance_variable_defined?(:@_current_user)
      @_current_user = Slots.configuration.authentication_model.valid_user?(jw_token)
    end
    def jw_token
      return @_jw_token if instance_variable_defined?(:@_jw_token)
      @_jw_token = authenticate_with_http_token do |token, options|
        Slots.configuration.authentication_model.valid_token?(token)
      end
    end

    def require_valid_token
      raise Slots::InvalidToken, 'Missing token' unless jw_token
    end
    def require_valid_user
      raise Slots::InvalidToken, 'Missing token' unless jw_token
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

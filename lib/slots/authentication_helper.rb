# frozen_string_literal: true

module Slots
  module AuthenticationHelper
    extend ActiveSupport::Concern

    included do
      include ActionController::HttpAuthentication::Token::ControllerMethods
    end

    def jw_token
      return @_jw_token if @_jw_token&.valid!

      if Slots.configuration.update_expired_session_tokens
        @_jw_token = Slots::Slokens.decode(authenticate_with_http_token { |t, _| t })
        if @_jw_token.expired? && @_jw_token.session.present? && Slots.configuration.session_lifetime
          @_current_user = Slots.configuration.authentication_model.from_sloken(@_jw_token)
          @_current_user&.update_session
        end
      else
        @_jw_token = Slots::Slokens.decode(authenticate_with_http_token { |t, _| t })
      end
      @_jw_token.valid!
    end

    def new_session_token
      @_jw_token = Slots::Slokens.decode(authenticate_with_http_token { |t, _| t })
      return false unless @_jw_token.session.present? && Slots.configuration.session_lifetime
      @_current_user = Slots.configuration.authentication_model.from_sloken(@_jw_token)
      return false unless @_current_user&.update_session
    end

    def current_user
      return @_current_user if instance_variable_defined?(:@_current_user)
      current_user = Slots.configuration.authentication_model.from_sloken(jw_token)
      # So if jw_token initalize current_user if expired
      @_current_user ||= current_user
    end
    def load_user
      current_user&.valid_in_database?
    end

    def set_token_header!
      # check if current user for logout
      response.set_header('authorization', "Bearer token=#{current_user.token}") if current_user&.new_token?
    end

    def require_valid_user(confirmed: true)
      raise Slots::AccessDenied unless current_user&.valid_user?(confirmed: confirmed)
    end
    def require_valid_loaded_user(confirmed: true)
      # Load user will make sure it is in the database and valid in the database
      raise Slots::InvalidToken, "User doesnt exist" unless load_user
      raise Slots::AccessDenied unless current_user&.valid_user?(confirmed: confirmed)
    end

    def require_valid_unconfirmed_user(**options)
      require_valid_user(**options, confirmed: false)
    end
    def require_valid_unconfirmed_loaded_user(**options)
      require_valid_loaded_user(**options, confirmed: false)
    end

    module ClassMethods
      def new_session_token!(**options)
        before_action :new_session_token, **options
      end

      def login_function(load_user: false, confirmed: true)
        return :require_valid_loaded_user if load_user && confirmed
        return :require_valid_user if confirmed
        return :require_valid_unconfirmed_loaded_user if load_user
        :require_valid_unconfirmed_user
      end

      def require_login!(load_user: false, confirmed: true, **options)
        before_action login_function(load_user: load_user, confirmed: confirmed), **options
        after_action :set_token_header!, **options
      end

      def ignore_login!(load_user: false, confirmed: true, **options)
        skip_before_action login_function(load_user: load_user, confirmed: confirmed), **options
        skip_after_action :set_token_header!, **options
      end

      def catch_invalid_token(response: {errors: {authentication: ['invalid or missing token']}}, status: :unauthorized)
        rescue_from Slots::InvalidToken do |exception|
          render json: response, status: status
        end
      end

      def catch_access_denied(response: {errors: {authorization: ["can't access"]}}, status: :forbidden)
        rescue_from Slots::AccessDenied do |exception|
          render json: response, status: status
        end
      end
    end
  end
end

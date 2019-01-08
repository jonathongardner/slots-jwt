# frozen_string_literal: true

module Slots
  module AuthenticationHelper
    extend ActiveSupport::Concern

    included do
      include ActionController::HttpAuthentication::Token::ControllerMethods
    end

    def jw_token
      return @_jw_token if @_jw_token&.valid!
      @_jw_token = Slots::Slokens.decode(authenticate_with_http_token { |t, _| t })
      @_jw_token.valid!
    end

    def new_session_token
      @_jw_token = Slots::Slokens.decode(authenticate_with_http_token { |t, _| t })
      return false unless @_jw_token.session && Slots.configuration.session_lifetime
      user = Slots.configuration.authentication_model.from_sloken(@_jw_token)
      return false unless user&.update_session
    end

    def current_user
      return @_current_user if instance_variable_defined?(:@_current_user)
      @_current_user = Slots.configuration.authentication_model.from_sloken(jw_token)
    end
    def load_user
      current_user&.valid_in_database?
    end

    def require_valid_user(confirmed: true)
      raise Slots::InvalidToken unless current_user&.valid_user?(confirmed: confirmed)
    end
    def require_valid_loaded_user(confirmed: true)
      # Load user will make sure it is in the database and valid in the database
      raise Slots::InvalidToken, "User doesnt exist" unless load_user
      raise Slots::InvalidToken unless current_user&.valid_user?(confirmed: confirmed)
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
        return :require_valid_unconfirmed_user
      end

      def require_login!(load_user: false, confirmed: true, **options)
        before_action login_function(load_user: load_user, confirmed: confirmed), **options
      end

      def ignore_login!(load_user: false, confirmed: true, **options)
        skip_before_action login_function(load_user: load_user, confirmed: confirmed), **options
      end

      def catch_invalid_token(response: {errors: {authentication: ['invalid or missing token']}}, status: :unauthorized)
        rescue_from Slots::InvalidToken do |exception|
          render json: response, status: status
        end
      end
    end
  end
end

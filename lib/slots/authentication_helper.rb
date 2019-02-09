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

    def update_expired_session_tokens
      return false unless Slots.configuration.session_lifetime
      @_jw_token = Slots::Slokens.decode(authenticate_with_http_token { |t, _| t })
      return false unless @_jw_token.expired? && @_jw_token.session.present?
      new_session_token
    end

    def new_session_token
      _current_user = Slots.configuration.authentication_model.from_sloken(@_jw_token)
      return false unless _current_user&.update_session
      @_current_user = _current_user
      true
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

    def require_valid_user
      # Load user will make sure it is in the database and valid in the database
      raise Slots::InvalidToken, "User doesnt exist" if @_require_load_user && !load_user
      access_denied! unless current_user && token_allowed?
    end
    def require_load_user
      # Use varaible so that if this action is prepended it will still onyl be called when checking for valid user,
      # i.e. so its not called before update_expired_session_tokens if set
      @_require_load_user = true
    end

    def access_denied!
      raise Slots::AccessDenied
    end

    def token_allowed?
      !(self.class._reject_token?(self))
    end

    module ClassMethods
      def update_expired_session_tokens!(**options)
        prepend_before_action :update_expired_session_tokens, **options
        after_action :set_token_header!, **options
      end

      def require_login!(load_user: false, **options)
        before_action :require_load_user, **options if load_user
        before_action :require_valid_user, **options
      end

      def require_user_load!(**options)
        prepend_before_action :require_load_user, **options
      end

      def ignore_login!(**options)
        skip_before_action :require_valid_user, **options
        skip_before_action :require_load_user, **options, raise: false
        skip_before_action :update_expired_session_tokens, **options, raise: false
        skip_after_action :set_token_header!, **options, raise: false
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

      def reject_token(&block)
        (@_reject_token ||= []).push(block)
      end
      def _reject_token?(con)
        (@_reject_token ||= []).any? { |b| con.instance_eval &b } || _superclass_reject_token?(con)
      end

      def _superclass_reject_token?(con)
        self.superclass.respond_to?('_reject_token?') && self.superclass._reject_token?(con)
      end
    end
  end
end

# frozen_string_literal: true

module Slots
  module JWT
    module AuthenticationHelper
      ALL = Object.new

      extend ActiveSupport::Concern

      included do
        include ActionController::HttpAuthentication::Token::ControllerMethods
        before_action :check_to_update_token
      end

      def check_to_update_token
        return unless self.class._update_token_user_info?(self) && current_user
        current_user.update_token_user_info
        set_token_header!
      end

      def jw_token
        return @_jw_token if instance_variable_defined?(:@_jw_token)
        token = authenticate_with_http_token { |t, _| t }
        @_jw_token = token ? Slots::JWT::Slokens.decode(token) : nil
      end

      def jw_token!
        jw_token&.valid!
      end

      def update_expired_session_tokens
        return false unless Slots::JWT.configuration.session_lifetime
        return false unless jw_token&.expired? && jw_token.session.present?
        new_session_token
      end

      def new_session_token
        _current_user = Slots::JWT.configuration.authentication_model.from_sloken(@_jw_token)
        return false unless _current_user&.update_session
        @_current_user = _current_user
        true
      end

      def current_user
        return @_current_user if instance_variable_defined?(:@_current_user)
        @_current_user = jw_token ? Slots::JWT.configuration.authentication_model.from_sloken(jw_token!) : nil
      end
      def load_user
        current_user&.valid_in_database? && current_user.allowed_new_token?
      end

      def set_token_header!
        # check if current user for logout
        response.set_header('authorization', "Bearer token=#{current_user.token}") if current_user&.new_token?
      end

      def require_valid_user
        # Load user will make sure it is in the database and valid in the database
        raise Slots::JWT::InvalidToken, "User doesnt exist" if @_require_load_user && !load_user
        access_denied! unless current_user && (@_ignore_callbacks || token_allowed?)
      end

      def require_load_user
        # Use varaible so that if this action is prepended it will still only be called when checking for valid user,
        # i.e. so its not called before update_expired_session_tokens if set
        @_require_load_user = true
      end

      def ignore_callbacks
        @_ignore_callbacks = true
      end

      def access_denied!
        raise Slots::JWT::AccessDenied
      end

      def token_allowed?
        !(self.class._reject_token?(self))
      end

      def new_token!(session)
        current_user.create_token(session)
        set_token_header!
      end

      def update_token!
        current_user.update_token
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

        def skip_callback!(**options)
          prepend_before_action :ignore_callbacks, **options
        end

        def ignore_login!(**options)
          skip_before_action :require_valid_user, **options
          skip_before_action :require_load_user, **options, raise: false
          skip_before_action :update_expired_session_tokens, **options, raise: false
          skip_after_action :set_token_header!, **options, raise: false
        end

        def catch_invalid_login(response: {errors: {authentication: ['login or password is invalid']}}, status: :unauthorized)
          rescue_from Slots::JWT::AuthenticationFailed do |exception|
            render json: response, status: status
          end
        end

        def catch_invalid_token(response: {errors: {authentication: ['invalid or missing token']}}, status: :unauthorized)
          rescue_from Slots::JWT::InvalidToken do |exception|
            render json: response, status: status
          end
        end

        def catch_access_denied(response: {errors: {authorization: ["can't access"]}}, status: :forbidden)
          rescue_from Slots::JWT::AccessDenied do |exception|
            render json: response, status: status
          end
        end

        def update_token_user_info(only: ALL, except: ALL, &block)
          raise 'Cant pass both only and except' unless only == ALL || except == ALL
          only = Array(only) if only != ALL
          except = Array(except) if except != ALL

          (@_update_token_user_info ||= []).push([only, except, block])
        end
        def _update_token_user_info?(con)
          (@_update_token_user_info ||= []).any? { |o, e, b| _check_to_update_token_user_info?(con, o, e, b) } || _superclass_update_token_user_info?(con)
        end
        def _check_to_update_token_user_info?(con, only, except, block)
          return false unless only == ALL || only.any? { |o| o.to_sym == con.action_name.to_sym }
          return false if except != ALL && except.any? { |e| e.to_sym == con.action_name.to_sym }
          con.instance_eval(&block)
        end

        def _superclass_update_token_user_info?(con)
          self.superclass.respond_to?('_update_token_user_info?') && self.superclass._update_token_user_info?(con)
        end

        def reject_token(only: ALL, except: ALL, &block)
          raise 'Cant pass both only and except' unless only == ALL || except == ALL
          only = Array(only) if only != ALL
          except = Array(except) if except != ALL

          (@_reject_token ||= []).push([only, except, block])
        end
        def _reject_token?(con)
          (@_reject_token ||= []).any? { |o, e, b| _check_to_reject?(con, o, e, b) } || _superclass_reject_token?(con)
        end
        def _check_to_reject?(con, only, except, block)
          return false unless only == ALL || only.any? { |o| o.to_sym == con.action_name.to_sym }
          return false if except != ALL && except.any? { |e| e.to_sym == con.action_name.to_sym }
          con.instance_eval(&block)
        end

        def _superclass_reject_token?(con)
          self.superclass.respond_to?('_reject_token?') && self.superclass._reject_token?(con)
        end
      end
    end
  end
end

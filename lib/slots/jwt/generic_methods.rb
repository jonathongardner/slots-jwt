# frozen_string_literal: true

module Slots
  module JWT
    module GenericMethods
      extend ActiveSupport::Concern

      included do
      end

      def allowed_new_token?
        !(self.class._reject_new_token?(self))
      end

      def failed_login
        !(self.class._failed_login(self))
      end

      def successful_login
        !(self.class._successful_login(self))
      end

      def run_token_created_callback
        self.class._token_created_callback(self)
      end

      def authenticate?(password)
        to_return = password.present? && persisted? && respond_to?(:authenticate) && authenticate(password) && allowed_new_token?
        to_return ? successful_login : failed_login
        to_return
      end

      def authenticate!(password)
        raise Slots::JWT::AuthenticationFailed unless self.authenticate?(password)
        true
      end

      module ClassMethods
        def find_for_authentication(login)
          Slots::JWT.configuration.logins.each do |k, v|
            next unless login&.match(v)
            return find_by(arel_table[k].lower.eq(login.downcase)) || new
          end
          new
        end

        def reject_new_token(&block)
          (@_reject_new_token ||= []).push(block)
        end
        def _reject_new_token?(user)
          (@_reject_new_token ||= []).any? { |b| user.instance_eval(&b) }
        end

        def failed_login(&block)
          (@_failed_login ||= []).push(block)
        end
        def _failed_login(user)
          (@_failed_login ||= []).any? { |b| user.instance_eval(&b) }
        end

        def successful_login(&block)
          (@_successful_login ||= []).push(block)
        end
        def _successful_login(user)
          (@_successful_login ||= []).any? { |b| user.instance_eval(&b) }
        end

        def token_created_callback(&block)
          (@_token_created_callback ||= []).push(block)
        end
        def _token_created_callback(user)
          (@_token_created_callback ||= []).each { |b| user.instance_eval(&b) }
        end
      end
    end
  end
end

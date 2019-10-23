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

      def run_token_created_callback
        self.class._token_created_callback(self)
      end

      def authenticate?(password)
        password.present? && persisted? && respond_to?(:authenticate) && authenticate(password) && allowed_new_token?
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

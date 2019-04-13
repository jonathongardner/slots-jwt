# frozen_string_literal: true

module Slots
  module GenericMethods
    extend ActiveSupport::Concern

    included do
    end

    def allowed_new_token?
      !(self.class._reject_new_token?(self))
    end

    def authenticate?(password)
      password.present? && persisted? && respond_to?(:authenticate) && authenticate(password) && allowed_new_token?
    end

    def authenticate!(password)
      raise Slots::AuthenticationFailed unless self.authenticate?(password)
      true
    end

    module ClassMethods
      def find_for_authentication(login)
        Slots.configuration.logins.each do |k, v|
          next unless login&.match(v)
          return find_by(arel_table[k].lower.eq(login.downcase)) || new
        end
        new
      end

      def reject_new_token(&block)
        (@_reject_new_token ||= []).push(block)
      end
      def _reject_new_token?(user)
        (@_reject_new_token ||= []).any? { |b| user.instance_eval &b }
      end
    end
  end
end

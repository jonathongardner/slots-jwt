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
      self.respond_to?(:authenticate) && self.authenticate(password) && self.allowed_new_token?
    end

    module ClassMethods
      def find_for_authentication(login)
        Slots.configuration.logins.each do |k, v|
          next unless login&.match(v)
          lower_case = self.arel_table[k].lower.eq(login.downcase)
          return self.where(lower_case).first
        end
        nil
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

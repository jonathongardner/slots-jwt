# frozen_string_literal: true

module Slots
  module GenericMethods
    extend ActiveSupport::Concern

    included do
    end

    def logged_in?
      @_logged_in.present?
    end

    def clear_logged_in
      @_logged_in = []
    end

    def add_logged_in(v)
      @_logged_in ||= []
      @_logged_in.push(v) unless @_logged_in.include?(v)
      logged_in?
    end

    def can_loggin(approved: true)
      return false if self.slots?(:approvable) && approved && !self.approved?
      true
    end

    def valid_user?(confirmed: true)
      return false if self.slots?(:confirmable) && confirmed && !self.confirmed?
      true
    end

    def authenticate?(password)
      add_logged_in(:password) if self.respond_to?(:authenticate) && self.authenticate(password) && self.can_loggin
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
    end
  end
end

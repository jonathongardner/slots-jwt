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

    def can_loggin
      return false if self.slots?(:approvable) && !self.approved?
      true
    end

    def authenticate?(password)
      add_logged_in(:password) if self.respond_to?(:authenticate) && self.authenticate(password) && self.can_loggin
    end

    module ClassMethods
      def find_for_authentication(login)
        Slots.configuration.logins.each do |k, v|
          return self.find_by(k => login) if login&.match(v)
        end
        nil
      end
    end
  end
end

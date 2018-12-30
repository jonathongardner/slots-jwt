# frozen_string_literal: true

module Slots
  module Confirmable
    extend ActiveSupport::Concern

    included do
      before_validation :set_new_confirmation_token, on: :create
      validate :confirmable_columns
    end

    def confirmable_columns
      self.errors.add(:confirmation_token, "can't exist if confirmed") if self.confirmed && self.confirmation_token.present?
      self.errors.add(:confirmation_token, "can't be blank") if !self.confirmed && self.confirmation_token.blank?
    end

    def set_new_confirmation_token
      self.confirmation_token = SecureRandom.hex(4)
    end

    def confirmed?
      self.confirmed
    end

    def confirm(token)
      return false unless self.confirmation_token == token
      self.update(confirmed: true, confirmation_token: nil)
    end

    module ClassMethods
    end
  end
end

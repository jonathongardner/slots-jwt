# frozen_string_literal: true

module Slots
  module Confirmable
    extend ActiveSupport::Concern

    included do
      before_validation :set_new_confirmation_token, if: :email_changed?
      validate :confirmable_columns
      after_commit :send_confirmation_email, if: :send_confirmation_email?
    end

    def send_confirmation_email?
      @send_confirmation_email
    end

    def confirmable_columns
      self.errors.add(:confirmation_token, "can't exist if confirmed") if self.confirmed && self.confirmation_token.present?
      self.errors.add(:confirmation_token, "can't be blank") if !self.confirmed && self.confirmation_token.blank?
    end

    def as_json(*)
      super.except('confirmation_token')
    end

    def set_new_confirmation_token
      self.confirmed = false
      self.confirmation_token = SecureRandom.hex(4)
      @send_confirmation_email = true
    end

    def confirmed?
      self.confirmed
    end

    def send_confirmation_email
      Rails.logger.warn("SLOTS: Confirmation email not sent. Need to override send_confirmation_email in authentication model")
    end

    def confirm(token)
      return false unless self.confirmation_token == token
      self.update(confirmed: true, confirmation_token: nil)
    end

    module ClassMethods
    end
  end
end

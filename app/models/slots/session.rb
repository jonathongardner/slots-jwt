# frozen_string_literal: true

module Slots
  class Session < ApplicationRecord
    belongs_to :user, session_assocaition
    before_validation :create_random_session, on: :create
    validates :session, :jwt_iat, presence: true
    validates :session, uniqueness: true

    def update_random_session
      self.session = SecureRandom.hex(32)
    end
    private
      def create_random_session
        update_random_session unless self.session
      end
  end
end

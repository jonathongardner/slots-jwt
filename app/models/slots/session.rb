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

    def self.expired
      self.where(self.arel_table[:created_at].lte(Slots.configuration.session_lifetime.ago))
    end

    def self.not_expired
      self.where(self.arel_table[:created_at].gt(Slots.configuration.session_lifetime.ago))
    end

    def self.matches_jwt(sloken_jws)
      self.not_expired
        .find_by(session: sloken_jws.session, jwt_iat: sloken_jws.iat)
    end
    private
      def create_random_session
        update_random_session unless self.session
      end
  end
end

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
      jwt_where = self.arel_table[:jwt_iat].eq(sloken_jws.iat)
      if Slots.configuration.previous_jwt_lifetime
        jwt_where = jwt_where.or(
          Arel::Nodes::Grouping.new(
            self.arel_table[:previous_jwt_iat].eq(sloken_jws.iat)
              .and(self.arel_table[:jwt_iat].gt(Slots.configuration.previous_jwt_lifetime.ago.to_i))
            )
        )
      end

      self.not_expired
        .where(jwt_where)
        .find_by(session: sloken_jws.session)
    end
    private
      def create_random_session
        update_random_session unless self.session
      end
  end
end

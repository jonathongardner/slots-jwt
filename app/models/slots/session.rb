# frozen_string_literal: true

module Slots
  class Session < ApplicationRecord
    belongs_to :user, session_assocaition
    validates :session, :jwt_iat, presence: true
    validates :session, uniqueness: true
  end
end

# frozen_string_literal: true

module Slots
  module Confirmable
    extend ActiveSupport::Concern

    included do
    end

    def confirmed?
      self.confirmed
    end

    module ClassMethods
    end
  end
end

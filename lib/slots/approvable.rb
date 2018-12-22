# frozen_string_literal: true

module Slots
  module Approvable
    extend ActiveSupport::Concern

    included do
    end

    def approved?
      self.approved
    end

    def can_approve?(to_approve)
      false
    end

    def approve!
      self.update!(approved: true)
    end

    module ClassMethods
    end
  end
end

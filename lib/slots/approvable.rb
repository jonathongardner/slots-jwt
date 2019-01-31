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

    def approve!(approved_pasted = nil)
      self.update!(approved: approved_pasted.nil? || approved_pasted)
    end

    module ClassMethods
    end
  end
end

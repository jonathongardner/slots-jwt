# frozen_string_literal: true

module Slots
  module JWT
    class ApplicationRecord < ActiveRecord::Base
      self.abstract_class = true
    end
  end
end

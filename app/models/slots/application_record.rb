# frozen_string_literal: true

module Slots
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end

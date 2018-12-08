# frozen_string_literal: true

require "slots/engine"
require "slots/database_authentication"
require "slots/generic_methods"
require "slots/generic_validations"
require "slots/configuration"
require "slots/extra_classes"
require "slots/tokens"

module Slots
  # Your code goes here...
  module Model
    def slots(*extensions)
      to_include = [GenericMethods, GenericValidations]
      @_slots_extensions = []
      if extensions.include?(:database_authentication)
        to_include.push(DatabaseAuthentication)
        @_slots_extensions.push(:database_authentication)
      end
      if extensions.include?(:tokens)
        to_include.push(Tokens)
        @_slots_extensions.push(:tokens)
      end

      slots_extensions_not_found = extensions - @_slots_extensions
      raise "The following slot extensions were not found: #{slots_extensions_not_found}" if slots_extensions_not_found.present?
      include *to_include
    end
  end
  ActiveRecord::Base.extend Slots::Model
end

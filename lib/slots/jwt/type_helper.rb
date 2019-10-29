# frozen_string_literal: true

module Slots
  module JWT
    module TypeHelper
      def self.included(mod)
        mod.module_eval do
          def initialize(*args, required_permission: nil, **kwargs, &block)
            required_permission(required_permission)
            # Pass on the default args:
            super(*args, **kwargs, &block)
          end
        end
      end
      # Call this method in an Object class to set the permission level:
      def required_permission(permission_level)
        @_required_permission = permission_level
      end

      # This method is overridden to customize object types:
      def to_graphql
        type_defn = super # returns a GraphQL::ObjectType
        # Get a configured value and assign it to metadata
        type_defn.metadata[:has_required_permission] = true
        type_defn.metadata[:required_permission] = @_required_permission
        type_defn
      end
    end
  end
end

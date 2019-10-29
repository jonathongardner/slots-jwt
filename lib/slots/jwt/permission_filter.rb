# frozen_string_literal: true

module Slots
  module JWT
    class PermissionFilter
      def initialize(current_user)
        @current_user = current_user
      end

      def call(schema_member, ctx)
        @schema_member = schema_member
        return true if _dont_check?
        allowed?
      end
      protected
        attr_reader :schema_member, :current_user

      private
        def _dont_check?
          !schema_member.metadata[:has_required_permission]
        end

        def required_permission
          schema_member.metadata[:required_permission]
        end

        def valid_loaded_user
          return @valid_loaded_user if instance_variable_defined?(:@valid_loaded_user)
          @valid_loaded_user = current_user&.valid_in_database? && current_user.allowed_new_token?
        end

        def is_admin
          valid_loaded_user && current_user.admin
        end
    end
  end
end

# frozen_string_literal: true

module Slots
  module JWT
    module DatabaseAuthentication
      extend ActiveSupport::Concern

      included do
        has_secure_password
      end

      # TODO allow super
      def as_json(*)
        super.except('password_digest')
      end

      module ClassMethods
      end
    end
  end
end

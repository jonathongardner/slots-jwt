# frozen_string_literal: true

require "slots/jwt/configuration"
require "slots/jwt/database_authentication"
require "slots/jwt/engine"
require "slots/jwt/extra_classes"
require "slots/jwt/generic_methods"
require "slots/jwt/generic_validations"
require "slots/jwt/slokens"
require "slots/jwt/tests"
require "slots/jwt/tokens"
require "slots/jwt/authentication_helper"
require "slots/jwt/permission_filter"
require "slots/jwt/type_helper"

module Slots
  module JWT
    module Model
      def session_assocaition
        {foreign_key: "#{Slots::JWT.configuration.authentication_model.to_s.underscore}_id", class_name: Slots::JWT.configuration.authentication_model.to_s}
      end

      def slots(*extensions)
        to_include = [GenericMethods, GenericValidations, Tokens]
        extensions.each do |e|
          extension = e.to_sym
          case extension
          when :database_authentication
            to_include.push(DatabaseAuthentication)
          else
            raise "The following slot extension was not found: #{extension}\nThe following are allows :database_authentication, :approvable, :confirmable"
          end
        end
        define_method(:slots?) { |v| extensions.include?(v) }

        include(*to_include)
        has_many :sessions, session_assocaition.merge(class_name: 'Slots::JWT::Session')
      end

      # module Controller
      #   extended do
      # include Slots::AuthenticationHelper
      #   end
      # end
    end
    ActiveRecord::Base.extend Slots::JWT::Model
    ActionController::API.include Slots::JWT::AuthenticationHelper
  end
end

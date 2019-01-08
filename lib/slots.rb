# frozen_string_literal: true

require "slots/approvable"
require "slots/configuration"
require "slots/confirmable"
require "slots/database_authentication"
require "slots/engine"
require "slots/extra_classes"
require "slots/generic_methods"
require "slots/generic_validations"
require "slots/slokens"
require "slots/tests"
require "slots/tokens"
require "slots/authentication_helper"

module Slots
  # Your code goes here...
  module Model
    def session_assocaition
      {foreign_key: "#{Slots.configuration.authentication_model.to_s.underscore}_id", class_name: Slots.configuration.authentication_model.to_s}
    end

    def slots(*extensions)
      to_include = [GenericMethods, GenericValidations, Tokens]
      extensions.each do |e|
        extension = e.to_sym
        case extension
        when :database_authentication
          to_include.push(DatabaseAuthentication)
        when :approvable
          to_include.push(Approvable)
        when :confirmable
          to_include.push(Confirmable)
        else
          raise "The following slot extension was not found: #{extension}\nThe following are allows :database_authentication, :approvable, :confirmable"
        end
      end
      define_method(:slots?) { |v| extensions.include?(v) }

      include(*to_include)
      has_many :sessions, session_assocaition.merge(class_name: 'Slots::Session')
    end

    # module Controller
    #   extended do
        # include Slots::AuthenticationHelper
    #   end
    # end
  end
  ActiveRecord::Base.extend Slots::Model
  ActionController::API.include Slots::AuthenticationHelper
end

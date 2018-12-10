# frozen_string_literal: true

require_dependency "slots/application_controller"
module Slots
  class SessionsController < ApplicationController
    include AuthenticationHelper

    require_login! except: [:sign_in, :valid_token]

    def sign_in
      @_current_user = _authentication_model.find_for_authentication(params[:login])

      raise Slots::AuthenticationFailed unless current_user&.authenticate?(params[:password])

      current_user.create_token(ActiveModel::Type::Boolean.new.cast(params[:session]))
      render json: current_user.as_json(methods: :token), status: :accepted
    end

    # def sign_out
    # end
    #

    def valid_token
      @_jw_token = authenticate_with_http_token do |token, options|
        Slots.configuration.authentication_model.valid_token_or_session?(token)
      end
      require_valid_token
      render json: current_user.as_json(methods: :token), status: :accepted
    end

    rescue_from Slots::AuthenticationFailed do |exception|
      render json: {errors: {authentication: ['login or password is invalid']}}, status: :unauthorized
    end

    catch_invalid_token

    private

      def _authentication_model
        Slots.configuration.authentication_model
      end
  end
end

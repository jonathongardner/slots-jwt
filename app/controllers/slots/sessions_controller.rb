# frozen_string_literal: true

require_dependency "slots/application_controller"
module Slots
  class SessionsController < ApplicationController
    include AuthenticationHelper

    require_login! except: [:sign_in]

    def sign_in
      @_current_user = _authentication_model.find_for_authentication(params[:login])

      raise Slots::AuthenticationFailed unless current_user&.authenticate?(params[:password])

      render json: current_user, status: :accepted
    end

    # def sign_out
    # end
    #

    def valid_token
      render json: current_user, status: :accepted
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

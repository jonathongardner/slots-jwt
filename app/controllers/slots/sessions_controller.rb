# frozen_string_literal: true

require_dependency "slots/application_controller"
module Slots
  class SessionsController < ApplicationController
    def sign_in
      @_current_user = _authentication_model.find_for_authentication(params[:login])

      raise Slots::AuthenticationFailed unless current_user&.authenticate?(params[:password])

      render json: current_user, status: :accepted
    end

    # def sign_out
    # end
    #
    # def valid_token
    # end

    def current_user
      @_current_user
    end

    private

      def _authentication_model
        Slots.configuration.authentication_model
      end
  end
end

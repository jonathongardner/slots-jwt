# frozen_string_literal: true

require_dependency "slots/application_controller"
module Slots
  class SettingsController < ApplicationController
    require_login! load_user: true, except: :confirm
    def approve
      authentication = Slots.configuration.authentication_model.find(params[:id])
      return render json: {errors: ["can't approve"]}, status: :forbidden unless current_user.can_approve?(authentication)
      authentication.approve!
      head :ok
    end

    def confirm
      require_valid_loaded_user(confirmed: false)
      if current_user.confirm(params[:confirmation_token])
        current_user.update_session if current_user.jwt.session
        render json: current_user.as_json(methods: :token), status: :ok
      else
        render json: {errors: ["can't confirm"]}, status: :unprocessable_entity #unauthorized
      end
    end

    private
  end
end

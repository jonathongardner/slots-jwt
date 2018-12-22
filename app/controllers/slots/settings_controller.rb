# frozen_string_literal: true

require_dependency "slots/application_controller"
module Slots
  class SettingsController < ApplicationController
    include AuthenticationHelper

    require_login! valid_user: true
    def approve
      authentication = Slots.configuration.authentication_model.find(params[:id])
      return render json: error_message, status: status_code unless current_user.can_approve?(authentication)
      authentication.approve!
      head :ok
    end

    private
      def error_message
        {errors: ["can't approve"]}
      end

      def status_code
        :forbidden
      end
  end
end

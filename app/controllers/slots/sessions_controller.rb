# frozen_string_literal: true

require_dependency "slots/application_controller"
module Slots
  class SessionsController < ApplicationController
    include AuthenticationHelper

    new_session_token! only: :update_session_token
    require_login! load_user: true, confirmed: false, only: :update_session_token
    require_login! except: [:sign_in, :update_session_token]

    def sign_in
      @_current_user = _authentication_model.find_for_authentication(params[:login])

      raise Slots::AuthenticationFailed unless current_user&.authenticate?(params[:password])

      current_user.create_token(ActiveModel::Type::Boolean.new.cast(params[:session]))
      render json: current_user.as_json(methods: :token), status: :accepted
    end

    def sign_out
      Slots::Session.find_by(session: jw_token.session)&.delete if jw_token.session
      head :ok
    end

    def update_session_token
      return render json: {errors: {token: ["doesn't have Session"]}}, status: :unprocessable_entity unless jw_token.session
      render json: current_user.as_json(methods: :token), status: :accepted
    end

    # def valid_token
    #   render json: current_user.as_json(methods: :token), status: :accepted
    # end

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

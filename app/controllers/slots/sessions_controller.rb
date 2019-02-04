# frozen_string_literal: true

require_dependency "slots/application_controller"
module Slots
  class SessionsController < ApplicationController
    update_expired_session_tokens! only: :update_session_token
    require_login! load_user: true, only: :update_session_token
    require_login! except: [:sign_in, :update_session_token]

    def sign_in
      @_current_user = _authentication_model.find_for_authentication(params[:login])

      raise Slots::AuthenticationFailed unless current_user&.authenticate?(params[:password])

      current_user.create_token(ActiveModel::Type::Boolean.new.cast(params[:session]))
      set_token_header!
      render json: current_user.as_json, status: :accepted
    end

    def sign_out
      Slots::Session.find_by(session: jw_token.session)&.delete if jw_token.session.present?
      head :ok
    end

    def update_session_token
      new_session_token if Slots.configuration.session_lifetime && jw_token.session.present? && !current_user.new_token?
      render json: current_user.as_json, status: :accepted
    end

    rescue_from Slots::AuthenticationFailed do |exception|
      render json: {errors: {authentication: ['login or password is invalid']}}, status: :unauthorized
    end

    # TODO need to change this to use local application_controller so if
    # the error messages are changed it will be reflected
    catch_invalid_token
    catch_access_denied

    private

      def _authentication_model
        Slots.configuration.authentication_model
      end
  end
end

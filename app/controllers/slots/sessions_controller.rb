# frozen_string_literal: true

module Slots
  class SessionsController < ApplicationController
    update_expired_session_tokens! only: :update_session_token # needed if token is expired
    require_user_load! only: :update_session_token
    require_login! only: [:update_session_token, :sign_out]
    skip_callback!

    def sign_in
      @_current_user = _authentication_model.find_for_authentication(params[:login])

      current_user.authenticate!(params[:password])

      new_token!(ActiveModel::Type::Boolean.new.cast(params[:session]))
      render json: current_user.as_json, status: :accepted
    end

    def sign_out
      Slots::Session.find_by(session: jw_token.session)&.delete if jw_token.session.present?
      head :ok
    end

    def update_session_token
      # TODO think about not allowing user to get new token here because then there
      current_user.update_token unless current_user.new_token?
      render json: current_user.as_json, status: :accepted
    end

    private

      def _authentication_model
        Slots.configuration.authentication_model
      end
  end
end

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

    private

      def _authentication_model
        Slots.configuration.authentication_model
      end
  end
end

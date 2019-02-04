# frozen_string_literal: true

class ADifferentController < ApplicationController
  update_expired_session_tokens! only: [:valid_user]
  require_login! load_user: true, only: [:valid_user]
  require_login! only: [:valid_token]

  def valid_user
    head :ok
  end

  def valid_token
    head :ok
  end

  catch_invalid_token(response: {errors: {my_message: ['Some custom message']}}, status: :im_a_teapot)
  catch_access_denied(response: {errors: {my_message: ['Another custom message']}}, status: :enhance_your_calm)
end

# frozen_string_literal: true

class IgnoreController < ApplicationController
  require_login!
  skip_callback! only: :action_one

  reject_token do
    current_user.username == 'someusername'
  end

  def action_one
    head :ok
  end

  def action_two
    head :ok
  end

  catch_access_denied(response: {errors: {my_message: ['Woahhhh caaaallmmm down']}}, status: :enhance_your_calm)
end

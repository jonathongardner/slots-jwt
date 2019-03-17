# frozen_string_literal: true

class RejectController < ApplicationController
  require_login!

  reject_token(only: :action_one) do
    current_user.username == 'anotherusername'
  end

  reject_token(except: [:action_one]) do
    current_user.username == 'someusername'
  end

  def action_one
    head :ok
  end

  def action_two
    head :ok
  end

  catch_access_denied(response: {errors: {my_message: ['Woah caaaallmmm down']}}, status: :enhance_your_calm)
end

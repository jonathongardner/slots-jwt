# frozen_string_literal: true

class UpdateUserTokenInfoController < ActionController::API
  update_token_user_info(only: :action_one) do
    next false unless current_user
    created_at_was = current_user.created_at.to_i
    current_user.valid_in_database? && current_user.created_at.to_i != created_at_was
  end

  update_token_user_info(except: [:action_one]) do
    next false unless current_user
    updated_at_was = current_user.updated_at.to_i
    current_user.valid_in_database? && current_user.updated_at.to_i != updated_at_was
  end

  def action_one
    head :ok
  end

  def action_two
    head :ok
  end
end

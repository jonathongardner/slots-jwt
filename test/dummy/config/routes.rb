# frozen_string_literal: true

Rails.application.routes.draw do
  get 'another/valid_user'
  get 'another/valid_token'
  get 'another/valid_token_with_update_expired'

  get 'a_different/valid_user'
  get 'a_different/valid_token'

  get 'reject/action_one'
  get 'reject/action_two'

  get 'ignore/action_one'
  get 'ignore/action_two'

  mount Slots::Engine => "/slots"
end

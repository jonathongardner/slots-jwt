# frozen_string_literal: true
user_model = Slots.configuration.authentication_model&.name&.underscore || ""
Slots::Engine.routes.draw do
  get 'sign_in', to: 'sessions#sign_in'
  post 'sign_in', to: 'sessions#sign_in'
  delete 'sign_out', to: 'sessions#sign_out'
  get 'update_session_token', to: 'sessions#update_session_token'
  # get 'valid_token', to: 'sessions#valid_token' TODO not sure if valid token is needed
end

# frozen_string_literal: true
user_model = Slots.configuration.authentication_model.name.underscore
Slots::Engine.routes.draw do
  post user_model.pluralize, to: 'manages#create', as: "create_#{user_model}"
  put user_model.pluralize, to: 'manages#update', as: "update_#{user_model}"
  patch user_model.pluralize, to: 'manages#update'

  get 'sign_in', to: 'sessions#sign_in'
  post 'sign_in'
  delete 'sign_out', to: 'sessions#sign_out'
  get 'update_session_token', to: 'sessions#update_session_token'
  # get 'valid_token', to: 'sessions#valid_token' TODO not sure if valid token is needed

  get 'approve/:id', to: 'settings#approve', as: :approve

  get 'new_confirmation_token', to: 'manages#new_confirmation_token', as: "new_confirmation_token"
  get 'confirm', to: 'settings#confirm', as: :confirm
end

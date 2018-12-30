# frozen_string_literal: true
user_model = Slots.configuration.authentication_model.name.underscore
Slots::Engine.routes.draw do
  post user_model.pluralize, to: 'manages#create', as: "create_#{user_model}"
  put user_model.pluralize, to: 'manages#update', as: "update_#{user_model}"
  patch user_model.pluralize, to: 'manages#update'

  get 'sign_in', to: 'sessions#sign_in'
  delete 'sign_out', to: 'sessions#sign_out'
  get 'valid_token', to: 'sessions#valid_token'

  get 'approve/:id', to: 'settings#approve', as: :approve
  get 'confirm', to: 'settings#confirm', as: :confirm
end

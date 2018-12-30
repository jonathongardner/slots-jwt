# frozen_string_literal: true

Slots::Engine.routes.draw do
  get 'sign_in', to: 'sessions#sign_in'
  delete 'sign_out', to: 'sessions#sign_out'
  get 'valid_token', to: 'sessions#valid_token'
  get 'approve/:id', to: 'settings#approve', as: :approve
  get 'confirm', to: 'settings#confirm', as: :confirm
end

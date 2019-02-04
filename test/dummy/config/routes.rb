# frozen_string_literal: true

Rails.application.routes.draw do
  get 'another/valid_user'
  get 'another/valid_token'

  get 'a_different/valid_user'
  get 'a_different/valid_token'
  mount Slots::Engine => "/slots"
end

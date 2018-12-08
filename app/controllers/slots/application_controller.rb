# frozen_string_literal: true

module Slots
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
    rescue_from Slots::AuthenticationFailed do |exception|
      render json: {errors: {authentication: ['login or password is invalid']}}, status: :unauthorized
    end
  end
end

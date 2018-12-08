# frozen_string_literal: true

require 'test_helper'
module Slots
  class SessionsControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    test "should sign_in with valid password" do
      user = users(:some_great_user)
      get sign_in_url params: {login: user.email, password: User.pass}
      assert_response :accepted
    end

    test "should sign_in with valid password and different logins" do
      Slots.configure do |config|
        config.logins = {email: /@/, username: //} # Most inclusive should be last
      end
      user = users(:some_great_user)

      get sign_in_url params: {login: user.email, password: User.pass}
      assert_response :accepted

      get sign_in_url params: {login: user.username, password: User.pass}
      assert_response :accepted
    end

    test "should not sign_in with invalid password" do
      user = users(:some_great_user)
      get sign_in_url params: {login: user.email, password: User.pass + '_something_else'}
      assert_response :unauthorized

      assert_response_error 'authentication', 'login or password is invalid'
    end

    test "should not sign_in with invalid login" do
      user = users(:some_great_user)
      get sign_in_url params: {login: 'DoesntExist@somewher.com', password: User.pass + '_something_else'}
      assert_response :unauthorized

      assert_response_error 'authentication', 'login or password is invalid'
    end

    # test "should get sign_out" do
    #   get sessions_sign_out_url
    #   assert_response :success
    # end
    #
    # test "should get valid_token" do
    #   get sessions_valid_token_url
    #   assert_response :success
    # end

    def parsed_response
      @parsed_response ||= JSON.parse(response.body)
    end

    def assert_response_error(*keys, error_message)
      assert parsed_response.key?('errors'), 'should be nested in errors'
      errors = parsed_response['errors']
      response_message = errors.dig(*keys)[0]
      assert_equal error_message, response_message, 'Error message should be the same'
    end

  end
end

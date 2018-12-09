# frozen_string_literal: true

require 'slots_integration_test.rb'
module Slots
  class SessionsControllerTest < SlotsIntegrationTest
    include Engine.routes.url_helpers, Slots::Tests

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
      get sign_in_url params: {login: 'DoesntExist@somewher.com', password: User.pass + '_something_else'}
      assert_response :unauthorized

      assert_response_error 'authentication', 'login or password is invalid'
    end

    test "should not return user for missing token" do
      get valid_token_url
      assert_response :unauthorized
      assert_response_error 'authentication', 'invalid or missing token'
    end
    test "should not return user for invalid token" do
      get valid_token_url, headers: token_header('foo')
      assert_response :unauthorized
      assert_response_error 'authentication', 'invalid or missing token'
    end
    test "should not return user for expired token" do
      user = users(:some_great_user)
      get valid_token_url, headers: token_header(create_token(identifier: user.email, exp: 1.minute.ago.to_i, iat: 2.minute.ago.to_i))
      assert_response :unauthorized
      assert_response_error 'authentication', 'invalid or missing token'
    end
    test "should return user for valid token" do
      user = users(:some_great_user)
      authorized_get user, valid_token_url
      assert_response :accepted
    end

    # test "should not return user for expired token" do
    #   get valid_token_url, headers: {'authorization' => 'Bearer token="foo"'}
    #   assert_response :unauthorized
    #   assert_response_error 'authentication', 'invalid or missing token'
    # end

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

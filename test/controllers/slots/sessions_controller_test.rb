# frozen_string_literal: true

require 'slots_integration_test.rb'
module Slots
  class SessionsControllerTest < SlotsIntegrationTest
    include Engine.routes.url_helpers, Slots::Tests

    test "should sign_in with valid password" do
      user = users(:some_great_user)
      get sign_in_url params: {login: user.email, password: User.pass}
      assert_response :accepted
      assert_decode_token(parsed_response['token'], identifier: user.email)
    end

    test "should sign_in with valid password and create session" do
      user = users(:some_great_user)
      assert_difference('Slots::Session.count') do
        get sign_in_url params: {login: user.email, password: User.pass, session: true}
        assert_response :accepted
        assert_decode_token(parsed_response['token'], identifier: user.email)
      end
    end

    test "should sign_in with valid password and different logins" do
      Slots.configure do |config|
        config.logins = {username: /\A[A-Za-z0-9_\-]+\Z/, email: //} # Most inclusive should be last
      end
      user = users(:some_great_user)

      get sign_in_url params: {login: user.email, password: User.pass}
      assert_response :accepted
      assert_decode_token(parsed_response['token'], identifier: user.username)

      get sign_in_url params: {login: user.username, password: User.pass}
      assert_response :accepted
      assert_decode_token(parsed_response['token'], identifier: user.username)
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
      assert_equal current_token, parsed_response['token'], 'Should return token passed'
    end

    # test "should get sign_out" do
    #   get sessions_sign_out_url
    #   assert_response :success
    # end
  end
end

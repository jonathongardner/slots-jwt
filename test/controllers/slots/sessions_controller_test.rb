# frozen_string_literal: true

require 'slots_integration_test.rb'
module Slots
  class SessionsControllerTest < SlotsIntegrationTest
    include Engine.routes.url_helpers, Slots::Tests

    test "should sign_in with valid password" do
      user = users(:some_great_user)
      get sign_in_url params: {login: user.email, password: User.pass}
      assert_response :accepted
      assert_decode_token(parsed_response['token'], user: user)
    end

    test "should sign_in with valid password and create session" do
      user = users(:some_great_user)
      assert_difference('Slots::Session.count') do
        get sign_in_url params: {login: user.email, password: User.pass, session: true}
        assert_response :accepted
        assert_decode_token(parsed_response['token'], user: user)
      end
    end

    test "should sign_in with valid password and different logins" do
      Slots.configure do |config|
        config.logins = {username: /\A[A-Za-z0-9_\-]+\Z/, email: //} # Most inclusive should be last
      end
      user = users(:some_great_user)

      get sign_in_url params: {login: user.email, password: User.pass}
      assert_response :accepted
      assert_decode_token(parsed_response['token'], user: user)

      get sign_in_url params: {login: user.username, password: User.pass}
      assert_response :accepted
      assert_decode_token(parsed_response['token'], user: user)
    end

    test "should not sign_in with invalid password" do
      user = users(:some_great_user)
      get sign_in_url params: {login: user.email, password: User.pass + '_something_else'}
      assert_response :unauthorized

      assert_response_error 'authentication', 'login or password is invalid'
    end

    test "should not sign_in unapproved" do
      user = users(:unapproved_user)
      get sign_in_url params: {login: user.email, password: User.pass}
      assert_response :unauthorized

      assert_response_error 'authentication', 'login or password is invalid'
    end

    test "should not sign_in with invalid login" do
      get sign_in_url params: {login: 'DoesntExist@somewher.com', password: User.pass + '_something_else'}
      assert_response :unauthorized

      assert_response_error 'authentication', 'login or password is invalid'
    end

    test "should return user for valid token" do
      user = users(:some_great_user)
      authorized_get user, valid_token_url
      assert_response :accepted
      assert_equal current_token, parsed_response['token'], 'Should return token passed'
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
      get valid_token_url, headers: token_header(create_token(user: user.as_json, exp: 1.minute.ago.to_i, iat: 2.minute.ago.to_i, extra_payload: {}))
      assert_response :unauthorized
      assert_response_error 'authentication', 'invalid or missing token'
    end
    test "should not return user for invalid user" do
      user = users(:some_great_user)
      token = create_token(user: user.as_json.merge('email' => 'SomethingElse'), exp: 1.minute.from_now.to_i, iat: 2.minute.ago.to_i, extra_payload: {})
      get valid_token_url, headers: token_header(token)
      assert_response :unauthorized
      assert_response_error 'authentication', 'invalid or missing token'
    end
    test "should return user for expired token with valid session" do
      user = users(:some_great_user)
      session = slots_sessions(:a_great_session)
      token = create_token(user: user.as_json, exp: 1.minute.ago.to_i, iat: session.jwt_iat, extra_payload: {session: session.session})
      get valid_token_url, headers: token_header(token)
      assert_response :accepted

      assert parsed_response['token'], 'Should return a token'
      assert current_token != parsed_response['token'], 'Should return a new token'
      assert_decode_token parsed_response['token'], user: user, extra_payload: {'session' => session.session}
    end
    test "should not return user for expired token with valid session" do
      Slots.configure do |config|
        config.session_lifetime = nil
      end
      user = users(:some_great_user)
      session = slots_sessions(:a_great_session)
      token = create_token(user: user.as_json, exp: 1.minute.ago.to_i, iat: session.jwt_iat, extra_payload: {session: session.session})
      get valid_token_url, headers: token_header(token)
      assert_response :unauthorized
      assert_response_error 'authentication', 'invalid or missing token'
    end
    test "should not return user for expired token with session if iat doesnt match" do
      user = users(:some_great_user)
      session = slots_sessions(:a_great_session)
      token = create_token(user: user.as_json, exp: 1.minute.ago.to_i, iat: 6.minutes.ago.to_i, extra_payload: {session: session.session})
      get valid_token_url, headers: token_header(token)
      assert_response :unauthorized
      assert_response_error 'authentication', 'invalid or missing token'
    end
    test "should not return user for expired token with session if session doesnt exist" do
      user = users(:some_great_user)
      session = slots_sessions(:a_great_session)
      token = create_token(user: user.as_json, exp: 1.minute.ago.to_i, iat: session.jwt_iat, extra_payload: {session: 'SomeSession'})
      get valid_token_url, headers: token_header(token)
      assert_response :unauthorized
      assert_response_error 'authentication', 'invalid or missing token'
    end
    test "should remove session on sign_out" do
      user = users(:some_great_user)
      session = slots_sessions(:a_great_session)
      token = create_token(user: user.as_json, exp: 1.minute.ago.to_i, iat: session.jwt_iat, extra_payload: {session: session.session})

      assert_difference('Slots::Session.count', -1) do
        delete sign_out_url, headers: token_header(token)
      end
      assert_response :ok
    end
    test "should not do anything if no session on sign_out" do
      user = users(:some_great_user)
      token = create_token(user: user.as_json, exp: 1.minute.from_now.to_i, iat: 6.minutes.ago.to_i, extra_payload: {})

      assert_no_difference('Slots::Session.count') do
        delete sign_out_url, headers: token_header(token)
      end
      assert_response :ok
    end

    # test "should get sign_out" do
    #   get sessions_sign_out_url
    #   assert_response :success
    # end
  end
end

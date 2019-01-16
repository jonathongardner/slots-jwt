# frozen_string_literal: true

require 'slots_integration_test.rb'
module Slots
  class SessionsControllerTest < SlotsIntegrationTest
    include Engine.routes.url_helpers, Slots::Tests

    #-----Generic logins------------
    test "should sign_in with valid password" do
      user = users(:some_great_user)
      get sign_in_url params: {login: user.email, password: User.pass}
      assert_response :accepted
      assert_decode_token(returned_token, user: user)
    end
    test "should sign_in with valid password and create session" do
      user = users(:some_great_user)
      assert_difference('Slots::Session.count') do
        get sign_in_url params: {login: user.email, password: User.pass, session: true}
        assert_response :accepted
        assert_decode_token(returned_token, user: user)
      end
    end
    test "should sign_in with valid password and different logins" do
      Slots.configure do |config|
        config.logins = {username: /\A[A-Za-z0-9_\-]+\Z/, email: //} # Most inclusive should be last
      end
      user = users(:some_great_user)

      get sign_in_url params: {login: user.email, password: User.pass}
      assert_response :accepted
      assert_decode_token(returned_token, user: user)

      get sign_in_url params: {login: user.username, password: User.pass}
      assert_response :accepted
      assert_decode_token(returned_token, user: user)
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
    #-----Generic logins------------

    #-----Add on logins------------
    test "should not sign_in unapproved" do
      user = users(:unapproved_user)
      get sign_in_url params: {login: user.email, password: User.pass}
      assert_response :unauthorized

      assert_response_error 'authentication', 'login or password is invalid'
    end
    test "should sign_in with valid password and unconfirmed user" do
      user = users(:unconfirmed_user)
      get sign_in_url params: {login: user.email, password: User.pass}
      assert_response :accepted
      assert_decode_token(returned_token, user: user)
    end
    #-----Add on logins------------

    #-----Generic Update Session token------------
    test "should not return user for update session token when no token" do
      user = users(:some_great_user)
      authorized_get user, update_session_token_url
      assert_response :unprocessable_entity

      assert_response_error 'token', "doesn't have Session"
    end
    test "should not return user for missing token when update session token" do
      get update_session_token_url
      assert_response :unauthorized
      assert_response_error 'authentication', 'invalid or missing token'
    end
    test "should not return user for invalid token when update session token" do
      get update_session_token_url, headers: token_header('foo')
      assert_response :unauthorized
      assert_response_error 'authentication', 'invalid or missing token'
    end
    test "should not return user for expired token when update session token" do
      user = users(:some_great_user)
      get update_session_token_url, headers: token_header(create_token(user: user.as_json, exp: 1.minute.ago.to_i, iat: 2.minute.ago.to_i, extra_payload: {}))
      assert_response :unauthorized
      assert_response_error 'authentication', 'invalid or missing token'
    end
    test "should not return user for invalid user when update session token" do
      user = users(:some_great_user)
      token = create_token(user: user.as_json.merge('email' => 'SomethingElse'), exp: 1.minute.from_now.to_i, iat: 2.minute.ago.to_i, extra_payload: {})
      get update_session_token_url, headers: token_header(token)
      assert_response :unauthorized
      assert_response_error 'authentication', 'invalid or missing token'
    end
    test "should return user for expired token with valid session when update session token" do
      user = users(:some_great_user)
      session = slots_sessions(:a_great_session)
      token = create_token(user: user.as_json, exp: 1.minute.ago.to_i, iat: session.jwt_iat, session: session.session, extra_payload: {})
      get update_session_token_url, headers: token_header(token)
      assert_response :accepted

      assert returned_token, 'Should return a token'
      assert current_token != returned_token, 'Should return a new token'
      assert_decode_token returned_token, user: user, session: session.session, extra_payload: {}
    end
    test "should not return user for expired token with valid session and session lifetime nil when update session token" do
      Slots.configure do |config|
        config.session_lifetime = nil
      end
      user = users(:some_great_user)
      session = slots_sessions(:a_great_session)
      token = create_token(user: user.as_json, exp: 1.minute.ago.to_i, iat: session.jwt_iat, session: session.session, extra_payload: {})
      get update_session_token_url, headers: token_header(token)
      assert_response :unauthorized
      assert_response_error 'authentication', 'invalid or missing token'
    end
    test "should not return user for expired token with session if iat doesnt match when update session token" do
      user = users(:some_great_user)
      session = slots_sessions(:a_great_session)
      token = create_token(user: user.as_json, exp: 1.minute.ago.to_i, iat: 6.minutes.ago.to_i, session: session.session, extra_payload: {})
      get update_session_token_url, headers: token_header(token)
      assert_response :unauthorized
      assert_response_error 'authentication', 'invalid or missing token'
    end
    test "should not return user for expired token with session if session doesnt exist when update session token" do
      user = users(:some_great_user)
      session = slots_sessions(:a_great_session)
      token = create_token(user: user.as_json, exp: 1.minute.ago.to_i, iat: session.jwt_iat, session: 'SomeSession', extra_payload: {})
      get update_session_token_url, headers: token_header(token)
      assert_response :unauthorized
      assert_response_error 'authentication', 'invalid or missing token'
    end
    #-----Generic Update Session token------------

    #-----Update Session token------------
    test "should return user for valid token and unconfirmed user when update session token" do
      user = users(:unconfirmed_user)
      session = slots_sessions(:unconfirmed_session)
      token = create_token(user: user.as_json, exp: 1.minute.ago.to_i, iat: session.jwt_iat, session: session.session, extra_payload: {})
      get update_session_token_url, headers: token_header(token)
      assert_response :accepted
      assert current_token != returned_token, 'Should return new token'
    end
    #-----Update Session token------------

    #-----Sign out------------
    test "should remove session on sign_out" do
      user = users(:some_great_user)
      session = slots_sessions(:a_great_session)
      token = create_token(user: user.as_json, exp: 1.minute.from_now.to_i, iat: session.jwt_iat, session: session.session, extra_payload: {})

      assert_difference('Slots::Session.count', -1) do
        delete sign_out_url, headers: token_header(token)
      end
      assert_response :ok
    end
    test "should not do anything if no session on sign_out" do
      user = users(:some_great_user)
      token = create_token(user: user.as_json, exp: 1.minute.from_now.to_i, iat: 6.minutes.ago.to_i, session: '', extra_payload: {})

      assert_no_difference('Slots::Session.count') do
        delete sign_out_url, headers: token_header(token)
      end
      assert_response :ok
    end
    #-----Sign out------------

    # test "should get sign_out" do
    #   get sessions_sign_out_url
    #   assert_response :success
    # end
  end
end

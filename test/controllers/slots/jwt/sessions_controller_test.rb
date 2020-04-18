# frozen_string_literal: true

require 'slots_integration_test.rb'
module Slots
  module JWT
    class SessionsControllerTest < SlotsIntegrationTest
      include Engine.routes.url_helpers, Slots::JWT::Tests

      #-----Generic logins------------
      test "should sign_in with valid password" do
        user = users(:some_great_user)
        get sign_in_url params: {login: user.email, password: User.pass}
        assert_response :accepted
        assert_decode_token(returned_token, user: user)
      end
      test "should sign_in with valid password and create session" do
        user = users(:some_great_user)
        assert_difference('Slots::JWT::Session.count') do
          get sign_in_url params: {login: user.email, password: User.pass, session: true}
          assert_response :accepted
          assert_decode_token(returned_token, user: user)
        end
      end
      test "should sign_in with valid password and different logins" do
        Slots::JWT.configure do |config|
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
      test "should not sign_in with weird user" do
        user = users(:weird_user)
        user.update_columns(failed_attempts: 5)
        get sign_in_url params: {login: user.email, password: User.pass}
        assert_response :unauthorized
        assert_response_error 'authentication', 'login or password is invalid'

        user.reload
        assert_equal 5, user.failed_attempts, 'Should not reset failed attampts'
      end
      test "should change failed attempts" do
        get sign_in_url params: {login: 'someEmailthaDoesntExist@somwhere.com', password: 'bad_password'}
        assert_response :unauthorized

        user = users(:some_great_user)


        get sign_in_url params: {login: user.email, password: 'bad_password'}
        assert_response :unauthorized
        user.reload
        assert_equal 1, user.failed_attempts, 'Should not reset failed attampts'

        get sign_in_url params: {login: user.email, password: 'bad_password'}
        assert_response :unauthorized
        user.reload
        assert_equal 2, user.failed_attempts, 'Should not reset failed attampts'

        get sign_in_url params: {login: user.email, password: User.pass}
        assert_response :success
        user.reload
        assert_equal 0, user.failed_attempts, 'Should reset failed attampts'
      end
      #-----Add on logins------------

      #-----Generic Update Session token------------
      test "should return user with updated token for update session token when no session" do
        user = users(:some_great_user)
        exp = 1.minutes.from_now.to_i
        old_iat = 2.minutes.ago.to_i

        current_token = create_token(user: user.as_json, exp: exp, iat: old_iat, session: '', extra_payload: {})
        get update_session_token_url, headers: token_header(current_token)
        assert_response :success

        assert_new_token current_token, user: user, exp: exp, extra_payload: {}
        assert_not_equal old_iat, 1, 'Should update iat'
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
        get update_session_token_url, headers: token_header(create_token(user: user.as_json, exp: 1.minute.ago.to_i, iat: 2.minute.ago.to_i, session: '', extra_payload: {}))
        assert_response :unauthorized
        assert_response_error 'authentication', 'invalid or missing token'
      end
      test "should not return user for invalid user when update session token" do
        user = users(:some_great_user)
        token = create_token(user: user.as_json.merge('email' => 'SomethingElse'), exp: 1.minute.from_now.to_i, iat: 2.minute.ago.to_i, session: '', extra_payload: {})
        get update_session_token_url, headers: token_header(token)
        assert_response :unauthorized
        assert_response_error 'authentication', 'invalid or missing token'
      end
      test "should return user for expired token with valid session when update session token" do
        user = users(:some_great_user)
        session = slots_jwt_sessions(:a_great_session)
        token = create_token(user: user.as_json, exp: 1.minute.ago.to_i, iat: session.jwt_iat, session: session.session, extra_payload: {})
        get update_session_token_url, headers: token_header(token)
        assert_response :accepted

        assert returned_token, 'Should return a token'
        assert current_token != returned_token, 'Should return a new token'
        assert_decode_token returned_token, user: user, session: session.session, extra_payload: {}
      end
      test "should return user with valid session when update session token" do
        user = users(:some_great_user)
        session = slots_jwt_sessions(:a_great_session)
        exp = 1.minute.from_now.to_i
        old_iat = session.jwt_iat
        token = create_token(user: user.as_json, exp: 1.minute.from_now.to_i, iat: session.jwt_iat, session: session.session, extra_payload: {})
        get update_session_token_url, headers: token_header(token)
        assert_response :accepted

        # assert_no_new_token
        assert_new_token current_token, user: user, session: session.session, exp: exp, extra_payload: {}
        assert_not_equal old_iat, session.reload.jwt_iat, 'Should update iat'
      end
      test "should not return user for expired token with valid session and session lifetime nil when update session token" do
        Slots::JWT.configure do |config|
          config.session_lifetime = nil
        end
        user = users(:some_great_user)
        session = slots_jwt_sessions(:a_great_session)
        token = create_token(user: user.as_json, exp: 1.minute.ago.to_i, iat: session.jwt_iat, session: session.session, extra_payload: {})
        get update_session_token_url, headers: token_header(token)
        assert_response :unauthorized
        assert_response_error 'authentication', 'invalid or missing token'
      end
      test "should not return user for expired token with session if iat doesnt match when update session token" do
        user = users(:some_great_user)
        session = slots_jwt_sessions(:a_great_session)
        token = create_token(user: user.as_json, exp: 1.minute.ago.to_i, iat: 6.minutes.ago.to_i, session: session.session, extra_payload: {})
        get update_session_token_url, headers: token_header(token)
        assert_response :unauthorized
        assert_response_error 'authentication', 'invalid or missing token'
      end
      test "should not return user for expired token with session if session doesnt exist when update session token" do
        user = users(:some_great_user)
        session = slots_jwt_sessions(:a_great_session)
        token = create_token(user: user.as_json, exp: 1.minute.ago.to_i, iat: session.jwt_iat, session: 'SomeSession', extra_payload: {})
        get update_session_token_url, headers: token_header(token)
        assert_response :unauthorized
        assert_response_error 'authentication', 'invalid or missing token'
      end
      #-----Generic Update Session token------------

      #-----Update Session token------------
      test "should not return user for valid token and weird user when update_session_token" do
        # Because weird user isnt allowed a new token
        user = users(:weird_user)
        session = slots_jwt_sessions(:weird_session)
        token = create_token(user: user.as_json, exp: 1.minute.ago.to_i, iat: session.jwt_iat, session: session.session, extra_payload: {})
        get update_session_token_url, headers: token_header(token)
        assert_response :unauthorized

        # assert_response_error 'user', "can't get new token"
      end
      #-----Update Session token------------

      #-----Sign out------------
      test "should remove session on sign_out" do
        user = users(:some_great_user)
        session = slots_jwt_sessions(:a_great_session)
        token = create_token(user: user.as_json, exp: 1.minute.from_now.to_i, iat: session.jwt_iat, session: session.session, extra_payload: {})

        assert_difference('Slots::JWT::Session.count', -1) do
          delete sign_out_url, headers: token_header(token)
        end
        assert_response :ok
      end
      test "should not do anything if no session on sign_out" do
        user = users(:some_great_user)
        token = create_token(user: user.as_json, exp: 1.minute.from_now.to_i, iat: 6.minutes.ago.to_i, session: '', extra_payload: {})

        assert_no_difference('Slots::JWT::Session.count') do
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
end

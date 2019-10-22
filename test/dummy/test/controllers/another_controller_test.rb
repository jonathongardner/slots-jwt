# frozen_string_literal: true

require 'slots_integration_test'
class AnotherControllerTest < SlotsIntegrationTest
  include Slots::Tests

  #----------------another_valid_user success----------------
  test "should return success for another_valid_user_url when valid token and user" do
    user = users(:some_great_user)
    authorized_get user, another_valid_user_url
    assert_response :success

    assert_no_new_token
  end
  test "should return success (and a new token) for expired token with valid session" do
    user, session, token = user_session_expired_token
    # Dont use authorized so can pass session
    get another_valid_user_url, headers: token_header(token)
    assert_response :success

    assert_new_token token, user: user, session: session.session, extra_payload: {}

    # Old token should still work for a few secs but it shouldnt return a new token
    get another_valid_user_url, headers: token_header(token)
    assert_response :success
    assert_no_new_token
  end
  test "should return success for expired token with valid session and iat matching previous iat older than configuration time" do
    Slots.configure do |config|
      config.previous_jwt_lifetime = 3.minutes
    end
    _, _, token = user_previous_session_expired_token
    # Dont use authorized so can pass session
    get another_valid_user_url, headers: token_header(token)
    assert_response :success

    assert_no_new_token
  end
  #----------------another_valid_user success----------------

  #----------------another_valid_user im_a_teapot----------------
  test "should return im_a_teapot for another_valid_user_url when invalid token" do
    get another_valid_user_url
    assert_response_im_a_teapot
    assert_response_error 'my_message', 'Some custom message'
  end
  test "should return im_a_teapot for another_valid_user_url when valid token and invalid user" do
    get another_valid_user_url, headers: invalid_token
    assert_response_im_a_teapot
    assert_response_error 'my_message', 'Some custom message'
  end
  test "should return im_a_teapot for another_valid_user_url when invalid email in token" do
    user = users(:some_great_user)
    user.email = 'somethingElse@somewhere.com'
    authorized_get user, another_valid_user_url
    assert_response_im_a_teapot
    assert_response_error 'my_message', 'Some custom message'
  end
  test "should return im_a_teapot for expired token without valid session" do
    user = users(:some_great_user)
    token = create_token(user: user.as_json, exp: 1.minute.ago.to_i, iat: 2.minutes.ago, extra_payload: {})
    # Dont use authorized so can pass session
    get another_valid_user_url, headers: token_header(token)
    assert_response_im_a_teapot
  end
  test "should return im_a_teapot for expired token with valid session but iat is different" do
    user = users(:some_great_user)
    session = slots_sessions(:a_great_session)
    token = create_token(user: user.as_json, exp: 1.minute.ago.to_i, iat: session.jwt_iat - 45, session: session.session, extra_payload: {})
    # Dont use authorized so can pass session
    get another_valid_user_url, headers: token_header(token)
    assert_response_im_a_teapot
  end
  test "should return im_a_teapot for expired token with valid session and iat older than previous_jwt_lifetime" do
    _, _, token = user_previous_session_expired_token
    # Dont use authorized so can pass session
    get another_valid_user_url, headers: token_header(token)
    assert_response_im_a_teapot
  end
  test "should return im_a_teapot for another_valid_user_url when expired token, valid session and weird_user" do
    # because weird user cannot get a new token
    _, _, token = user_session_expired_token([:weird_user, :weird_session])
    # Dont use authorized so can pass session
    get another_valid_user_url, headers: token_header(token)
    assert_response_im_a_teapot
  end
  #----------------another_valid_user im_a_teapot----------------

  #----------------another_valid_user enhance_your_calm----------------
  test "should return enhance_your_calm for another_valid_user_url when valid token and another_great_user" do
    user = users(:another_great_user)
    authorized_get user, another_valid_user_url
    assert_response_enhance_your_calm
    assert_response_error 'my_message', 'Another custom message'
  end
  test "should return enhance_your_calm for another_valid_user_url when expired token, valid session and another_great_user" do
    # becasue weird user is not allowed to login
    _, _, token = user_session_expired_token([:another_great_user, :another_great_session])
    # Dont use authorized so can pass session
    get another_valid_user_url, headers: token_header(token)
    assert_response_enhance_your_calm
  end
  #----------------another_valid_user enhance_your_calm----------------


  #----------------another_valid_token_url success----------------
  test "should return success for another_valid_token_url when valid token and user" do
    user = users(:some_great_user)
    authorized_get user, another_valid_token_url
    assert_response :success
  end
  test "should return success for another_valid_token_url when valid token and invalid user" do
    get another_valid_token_url, headers: invalid_token
    assert_response :success
  end
  #----------------another_valid_token_url success----------------

  #----------------another_valid_token_url im_a_teapot----------------
  test "should return enhance_your_calm for another_valid_token_url when no token" do
    get another_valid_token_url
    assert_response_enhance_your_calm
    assert_response_error 'my_message', 'Another custom message'
  end
  test "should return im_a_teapot for another_valid_token_url when invalid token" do
    get another_valid_token_url, headers: token_header('Some Invalid Token')
    assert_response_im_a_teapot
    assert_response_error 'my_message', 'Some custom message'
  end
  test "should return im_a_teapot for expired token with valid session" do
    # Because update_expired_session_tokens! not set on this action
    _, _, token = user_session_expired_token
    # Dont use authorized so can pass session
    get another_valid_token_url, headers: token_header(token)
    assert_response_im_a_teapot
  end
  #----------------another_valid_token_url im_a_teapot----------------

  #----------------another_valid_token_url enhance_your_calm----------------
  test "should return enhance_your_calm for another_valid_token_url when valid token and another_great_user" do
    user = users(:another_great_user)
    authorized_get user, another_valid_token_url
    assert_response_enhance_your_calm
    assert_response_error 'my_message', 'Another custom message'
  end
  #----------------another_valid_token_url enhance_your_calm----------------

  #----------------another_valid_token_with_update_expired_url success----------------
  test "should return success for another_valid_token_with_update_expired_url when valid token and user" do
    user = users(:some_great_user)
    authorized_get user, another_valid_token_with_update_expired_url
    assert_response :success
  end
  test "should return success for another_valid_token_with_update_expired when valid token and invalid user" do
    get another_valid_token_with_update_expired_url, headers: invalid_token
    assert_response :success
  end
  #----------------another_valid_token_with_update_expired_url success----------------

  #----------------another_valid_token_with_update_expired_url im_a_teapot----------------
  test "should return im_a_teapot for another_valid_token_with_update_expired_url when expired valid token and invalid user" do
    session = slots_sessions(:a_great_session)
    get another_valid_token_with_update_expired_url, headers: invalid_token(exp: 1.minute.ago.to_i, iat: session.jwt_iat, session: session.session)
    assert_response_im_a_teapot
    assert_no_new_token
  end
  test "should return im_a_teapot for another_valid_token_with_update_expired_url when expired valid token, valid user but cant get new token" do
    _, _, token = user_session_expired_token([:weird_user, :weird_session])
    get another_valid_token_with_update_expired_url, headers: token_header(token)
    assert_response_im_a_teapot
    assert_no_new_token
  end
  #----------------another_valid_token_with_update_expired_url im_a_teapot----------------

  def invalid_token(user: nil, exp: 1.minute.from_now.to_i, iat: 2.minute.ago.to_i, session:'')
    user ||= users(:some_great_user)
    token_header(create_token(user: {id: user.id, username: 'notweird'}, exp: exp, iat: iat, session: session, extra_payload: {}))
  end

  def assert_response_im_a_teapot
    assert_equal '418', response.code, "Expected response to be a <418: Im A Teapot> but was a <#{response.code}>"
  end

  def assert_response_enhance_your_calm
    assert_equal '420', response.code, "Expected response to be a <420: Enhance Your Calm> but was a <#{response.code}>"
  end

  def user_session_expired_token(sym = [:some_great_user, :a_great_session])
    # TODO WHY am I passing an array???
    user = users(sym[0])
    session = slots_sessions(sym[1])
    token = create_token(user: user.as_json, exp: 1.minute.ago.to_i, iat: session.jwt_iat, session: session.session, extra_payload: {})
    return user, session, token
  end

  def user_previous_session_expired_token(sym = [:some_great_user, :a_great_session])
    user = users(sym[0])
    session = slots_sessions(sym[1])
    token = create_token(user: user.as_json, exp: 1.minute.ago.to_i, iat: session.previous_jwt_iat, session: session.session, extra_payload: {})
    return user, session, token
  end
end

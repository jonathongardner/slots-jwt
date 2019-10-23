# frozen_string_literal: true

require 'slots_test'
class UserTest < SlotsTest
  # Need to use User because config changin model to TokenUser needs to be done before load

  test "should create valid token with session" do
    user = users(:another_great_user)
    assert_difference('Slots::JWT::Session.count') do
      token = user.create_token(true)
      assert_decode_token token, user: user, extra_payload: {}, session: user.sessions.second.session
    end
  end

  test "should not create token with session if session_lifetime is nil" do
    Slots::JWT.configure do |config|
      config.session_lifetime = nil
    end

    user = users(:another_great_user)
    assert_no_difference('Slots::JWT::Session.count') do
      token = user.create_token(true)
      assert_decode_token token, user: user, extra_payload: {}
    end
  end

  test "sould not return password or confirmation_token when using as/to_json" do
    user = users(:another_great_user)
    assert_not user.as_json.key?('password_digest'), 'Should not have password_digest when converting to json'
    assert_not user.as_json.key?('confirmation_token'), 'Should not have confirmation_token when converting to json'
    assert_not JSON.parse(user.to_json).key?('password_digest'), 'Should not have password_digest when converting to json'
    assert_not JSON.parse(user.to_json).key?('confirmation_token'), 'Should not have confirmation_token when converting to json'
    assert_not user.as_json(except: [:email]).key?('email'), 'Should still use as json properties'
  end

  #-----------------------TOKEN------------------------
  # TODO should maybe be more like session_controller test
  test "should update session with updated user, iat, and exp" do
    user, exp, iat = add_old_jws_to_user(session: :a_great_session)

    assert user.update_session, 'should update session'
    jws = user.jwt
    assert_decode_token jws.token, user: user, exp: jws.exp, iat: jws.iat, extra_payload: {}
    assert_not_equal exp, jws.exp
    assert_not_equal iat, jws.iat
  end

  test "should update token data with new data" do
    user, exp, iat = add_old_jws_to_user
    user.username = 'SOMETHINGNEW'

    user.update_token
    jws = user.jwt
    assert_decode_token jws.token, user: user, exp: jws.exp, iat: jws.iat, extra_payload: {}
    assert_equal exp, jws.exp
    assert iat < jws.iat, 'Should only update iat'
  end

  def add_old_jws_to_user(user: :some_great_user, session: nil)
    exp = 2.minute.from_now.to_i
    u = users(user)
    s = session ? slots_jwt_sessions(session) : nil
    iat = s&.jwt_iat || 2.minute.ago.to_i
    token = create_token(user: u.as_json, exp: exp, iat: iat, extra_payload: {}, session: s&.session || '')
    jws = Slots::JWT::Slokens.decode(token)
    return u.set_token!(jws), exp, iat
  end
  #-----------------------TOKEN------------------------
end

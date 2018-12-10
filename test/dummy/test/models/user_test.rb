# frozen_string_literal: true

require 'slots_test'
class UserTest < SlotsTest
  # Need to use User because config changin model to TokenUser needs to be done before load
  test "should validate expired token with session" do
    user = users(:some_great_user)
    session = slots_sessions(:a_great_session)
    token = create_token(identifier: user.jwt_identifier, exp: 1.minute.ago.to_i, iat: session.jwt_iat, session: session.session)

    assert_not TokenUser.valid_token?(token), 'Token should not be valid without session'
    sloken = User.valid_token_or_session?(token)
    assert sloken, 'Token should be valid because of session'

    assert token != sloken.token, 'Token should be updated to a valid token'
    assert_decode_token sloken.token, identifier: user.email, extra_payload: {'session' => session.session}
  end

  test "should not validate expired token with session if session_lifetime is nil" do
    Slots.configure do |config|
      config.session_lifetime = nil
    end
    user = users(:some_great_user)
    session = slots_sessions(:a_great_session)
    token = create_token(identifier: user.jwt_identifier, exp: 1.minute.ago.to_i, iat: session.jwt_iat, session: session.session)

    assert_not TokenUser.valid_token_or_session?(token), 'Token should not be valid'
    assert_nil user.token, 'Token should not be updated to a valid token'
  end

  test "should not validate expired token with session if iat doesnt match" do
    user = users(:some_great_user)
    session = slots_sessions(:a_great_session)
    token = create_token(identifier: user.jwt_identifier, exp: 1.minute.ago.to_i, iat: 6.minutes.ago.to_i, session: session.session)

    assert_not TokenUser.valid_token_or_session?(token), 'Token should not be valid'
    assert_nil user.token, 'Token should not be updated to a valid token'
  end

  test "should not validate expired token with session if session doesnt exist" do
    user = users(:some_great_user)
    session = slots_sessions(:a_great_session)
    token = create_token(identifier: user.jwt_identifier, exp: 1.minute.ago.to_i, iat: session.jwt_iat, session: 'SomeSession')

    assert_not TokenUser.valid_token_or_session?(token), 'Token should not be valid'
    assert_nil user.token, 'Token should not be updated to a valid token'
  end

  test "should create valid token with session" do
    user = users(:another_great_user)
    assert_difference('Slots::Session.count') do
      token = user.create_token(true)
      assert_decode_token token, identifier: user.email, extra_payload: {'session' => user.sessions.first.session}
    end
  end

  test "should not create token with session if session_lifetime is nil" do
    Slots.configure do |config|
      config.session_lifetime = nil
    end

    user = users(:another_great_user)
    assert_no_difference('Slots::Session.count') do
      token = user.create_token(true)
      assert_decode_token token, identifier: user.email, extra_payload: {}
    end
  end
end

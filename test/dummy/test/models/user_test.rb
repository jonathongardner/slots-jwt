# frozen_string_literal: true

require 'slots_test'
class UserTest < SlotsTest
  # Need to use User because config changin model to TokenUser needs to be done before load

  test "should create valid token with session" do
    user = users(:another_great_user)
    assert_difference('Slots::Session.count') do
      token = user.create_token(true)
      assert_decode_token token, user: user, extra_payload: {}, session: user.sessions.first.session
    end
  end

  test "should not create token with session if session_lifetime is nil" do
    Slots.configure do |config|
      config.session_lifetime = nil
    end

    user = users(:another_great_user)
    assert_no_difference('Slots::Session.count') do
      token = user.create_token(true)
      assert_decode_token token, user: user, extra_payload: {}
    end
  end

  test "unconfirmed_user should not be valid" do
    user = users(:unconfirmed_user)
    assert_not user.valid_user?, 'unconfirmed_user should not be valid'
    assert user.valid_user?(confirmed: false), 'unconfirmed_user should be valid if unconfirmed: false'
  end

  test "sould not return password or confirmation_token when using as/to_json" do
    user = users(:another_great_user)
    assert_not user.as_json.key?('password_digest'), 'Should not have password_digest when converting to json'
    assert_not user.as_json.key?('confirmation_token'), 'Should not have confirmation_token when converting to json'
    assert_not JSON.parse(user.to_json).key?('password_digest'), 'Should not have password_digest when converting to json'
    assert_not JSON.parse(user.to_json).key?('confirmation_token'), 'Should not have confirmation_token when converting to json'
    assert_not user.as_json(except: [:email]).key?('email'), 'Should still use as json properties'
  end
end

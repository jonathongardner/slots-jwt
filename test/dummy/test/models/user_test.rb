# frozen_string_literal: true

require 'slots_test'
class UserTest < SlotsTest
  # Need to use User because config changin model to TokenUser needs to be done before load

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

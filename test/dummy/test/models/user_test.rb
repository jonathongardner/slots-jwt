# frozen_string_literal: true

require 'slots_test'
class UserTest < SlotsTest
  test "should create valid token with session" do
    # Need to use User because config changin model to TokenUser needs to be done before load
    user = users(:another_great_user)
    assert_equal User.jwt_identifier_column, :email, 'JWT identifier column should be first identifier in login'
    assert_equal user.email, user.jwt_identifier, 'JWT identifier should be value of first identifier in login'
    assert_difference('Slots::Session.count') do
      token = user.create_token(true)
      assert_decode_token token, identifier: user.email, extra_payload: {'session' => user.sessions.first.session}
    end
  end
end

# frozen_string_literal: true

require 'slots_test'
class TokenUserTest < SlotsTest
  test "should create valid token" do
    user = token_users(:some_great_token_user)
    assert_singleton_method user, :run_token_created_callback do
      assert_equal TokenUser.jwt_identifier_column, :email, 'JWT identifier column should be first identifier in login'
      assert_equal user.email, user.jwt_identifier, 'JWT identifier should be value of first identifier in login'
      assert_no_difference('Slots::Session.count') do
        assert_decode_token user.create_token(false), user: user
      end
    end
  end

  test "should create valid token with first identifier from login" do
    Slots.configure do |config|
      config.logins = {username: /\A[A-Za-z0-9_\-]+\Z/, email: //} # Most inclusive should be last
    end
    user = token_users(:some_great_token_user)
    assert_equal TokenUser.jwt_identifier_column, :username, 'JWT identifier column should be first identifier in login'
    assert_equal user.username, user.jwt_identifier, 'JWT identifier should be value of first identifier in login'
    assert_decode_token user.create_token(false), user: user
  end

  test "should return created token" do
    user = token_users(:some_great_token_user)
    assert_nil user.token, 'Should not return token because not created or validated with one'
    token = user.create_token(false)
    assert_equal token, user.token, 'Should return created token'
  end
end

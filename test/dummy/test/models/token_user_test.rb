# frozen_string_literal: true

require 'slots_test'
class TokenUserTest < SlotsTest
  test "should validate valid token" do
    user = token_users(:some_great_token_user)
    token = create_token(identifier: user.jwt_identifier, exp: 1.minute.from_now.to_i, iat: 1.minute.ago.to_i)

    assert TokenUser.valid_token?(token), 'Token should be valid'
    assert_equal user, TokenUser.valid_token_and_user?(token), 'Valid user should be identifier user'
  end

  test "should not validate invalid token" do
    user = token_users(:some_great_token_user)
    token = create_token('AnotherSecret', identifier: user.jwt_identifier, exp: 1.minute.from_now.to_i, iat: 1.minute.ago.to_i)

    assert_not TokenUser.valid_token?(token), 'Token should not be valid'
    assert_nil TokenUser.valid_token_and_user?(token), 'Should return nil for invaluid token'
  end

  test "should create valid token" do
    user = token_users(:some_great_token_user)
    assert_equal TokenUser.jwt_identifier_column, :email, 'JWT identifier column should be first identifier in login'
    assert_equal user.email, user.jwt_identifier, 'JWT identifier should be value of first identifier in login'
    assert_no_difference('Slots::Session.count') do
      assert_decode_token user.create_token(false), identifier: user.email
    end
  end

  test "should create valid token with first identifier from login" do
    Slots.configure do |config|
      config.logins = {username: /\A[A-Za-z0-9_\-]+\Z/, email: //} # Most inclusive should be last
    end
    user = token_users(:some_great_token_user)
    assert_equal TokenUser.jwt_identifier_column, :username, 'JWT identifier column should be first identifier in login'
    assert_equal user.username, user.jwt_identifier, 'JWT identifier should be value of first identifier in login'
    assert_decode_token user.create_token(false), identifier: user.username
  end

  test "should return created token" do
    user = token_users(:some_great_token_user)
    assert_nil user.token, 'Should not return token because not created or validated with one'
    token = user.create_token(false)
    assert_equal token, user.token, 'Should return created token'
  end

  test "should return updated token" do
    user = token_users(:some_great_token_user)
    token = create_token(identifier: user.jwt_identifier, exp: 1.minute.from_now.to_i, iat: 1.minute.ago.to_i)
    assert_nil user.token, 'Should not return token because not created or validated with one'
    validated_user = TokenUser.valid_token_and_user?(token)
    assert_equal token, validated_user.token, 'Should return created token'
  end
end

# frozen_string_literal: true

require 'slots_test'
class TokenUserTest < SlotsTest
  test "should create valid token" do
    user = token_users(:some_great_token_user)
    assert_equal TokenUser.jwt_identifier_column, :email, 'JWT identifier column should be first identifier in login'
    assert_equal user.email, user.jwt_identifier, 'JWT identifier should be value of first identifier in login'
    assert_no_difference('Slots::Session.count') do
      assert_decode_token user.create_token(false), user: user
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

  def add_old_jws_to_user(sym = :some_great_token_user)
    exp = 2.minute.from_now.to_i
    iat = 2.minute.ago.to_i
    user = token_users(sym)
    token = create_token(user: user.as_json, exp: exp, iat: iat, extra_payload: {})
    jws = Slots::Slokens.decode(token)
    assert_decode_token jws.token, user: user, exp: exp, iat: iat, extra_payload: {}
    return user.set_token!(jws), exp, iat
  end
  # test "should update session with updated user, iat, and exp" do
  #   user, exp, iat = add_old_jws_to_user
  #   user.username = 'SOMETHINGNEW'
  #
  #   user.update_token
  #   jws = user.jwt
  #   assert_decode_token jws.token, user: user, exp: jws.exp, iat: jws.iat, extra_payload: {}
  #   assert_not_equal exp, jws.exp
  #   assert_not_equal iat, jws.iat
  # end
  test "should update token data with new data" do
    user, exp, iat = add_old_jws_to_user
    user.username = 'SOMETHINGNEW'

    user.update_token
    jws = user.jwt
    assert_decode_token jws.token, user: user, exp: jws.exp, iat: jws.iat, extra_payload: {}
    assert_equal exp, jws.exp
    assert_equal iat, jws.iat
  end
end

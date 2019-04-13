# frozen_string_literal: true

require 'slots_test'
class SlotsJwtTest < SlotsTest
  test "should decode valid token" do
    user = {'id' => 'SomeIdentifier'}
    exp = 1.minute.from_now.to_i
    iat = 1.minute.ago.to_i

    jws = Slots::Slokens.decode(create_token(exp: exp, iat: iat, extra_payload: {}, user: user, session: ''))

    assert jws.valid?, 'Token should be valid'
    assert_equal user, jws.authentication_model_values, 'Identifer should be equal to encoded identifier'
    assert_equal exp, jws.exp, 'exp should be equal to encoded exp'
    assert_equal iat, jws.iat, 'iat should be equal to encoded iat'
  end
  test "should decode valid token using config secret" do
    new_secret = 'my0ther$ecr3t'
    user = {'id' => 'SomeIdentifier'}
    exp = 1.minute.from_now.to_i
    iat = 1.minute.ago.to_i

    assert_singleton_method(Slots.configuration, :secret, to_return: new_secret) do
      jws = Slots::Slokens.decode(create_token(new_secret, exp: exp, iat: iat, extra_payload: {}, user: user, session: ''))

      assert jws.valid?, 'Token should be valid'
      assert_equal user, jws.authentication_model_values, 'Identifer should be equal to encoded identifier'
      assert_equal exp, jws.exp, 'exp should be equal to encoded exp'
      assert_equal iat, jws.iat, 'iat should be equal to encoded iat'
    end
  end
  test "should encode valid token" do
    user = {'id' => 'SomeIdentifier'}
    extra_payload = {'something_else' => 47}
    jws = Slots::Slokens.encode(user, extra_payload)
    assert_decode_token jws.token, user: user, exp: jws.exp, iat: jws.iat, extra_payload: extra_payload
  end
  test "should encode using config secret" do
    new_secret = 'my0ther$ecr3t'
    user = {'id' => 'SomeIdentifier'}
    extra_payload = {'something_else' => 47}

    assert_singleton_method(Slots.configuration, :secret, to_return: new_secret) do
      jws = Slots::Slokens.encode(user, extra_payload)
      assert_decode_token jws.token, user: user, exp: jws.exp, iat: jws.iat, extra_payload: extra_payload, secret: new_secret
    end
  end

  test "should pass iat to decode token" do
    hash = {session: '', exp: 1.minute.from_now.to_i, user: {}}
    old_iat = 1553294000
    old_token = create_token(iat: old_iat, **hash)
    assert_singleton_method(Slots.configuration, :secret, to_return: 'my$ecr3t', with: old_iat) do
      Slots::Slokens.decode(old_token)
    end

    new_iat = 1553295000
    new_token = create_token(iat: new_iat, **hash)
    assert_singleton_method(Slots.configuration, :secret, to_return: 'my$ecr3t', with: new_iat) do
      Slots::Slokens.decode(new_token)
    end
  end

  test "should raise error for invalid token" do
    jws, _, _ = creat_valid_jws

    assert_singleton_method(jws, :valid?, to_return: false) do
      error_raised_with_messege(Slots::InvalidToken, "Invalid Token") do
        jws.valid!
      end
    end

    assert_singleton_method(jws, :valid?, to_return: true) do
      jws.valid!
    end
  end

  test "should not decode token" do
    refute Slots::Slokens.decode('FakeToken').valid?, 'Should return false for token not formatted correctly'
    refute Slots::Slokens.decode("FakeToken.#{Base64.encode64('{]')}.cool").valid?, 'Should return false for json not valid'
    refute Slots::Slokens.decode("FakeToken.#{Base64.encode64('[]')}.cool").valid?, 'Should return false for none hash'

    refute create_jws(valid_hash(iat: '')).valid?, 'Should return false for bad iat'
    refute create_jws(valid_hash.except(:iat)).valid?, 'Should return false for missing iat'
    refute create_jws(valid_hash(exp: 1.minute.ago.to_i)).valid?, 'Should return false for exp'
    refute create_jws(valid_hash(exp: '')).valid?, 'Should return false for bad exp'
    refute create_jws(valid_hash.except(:exp)).valid?, 'Should return false for missing exp'

    refute create_jws(valid_hash.except(:user)).valid?, 'Should return false for missing user'
    refute create_jws(valid_hash.except(:session)).valid?, 'Should return false for missing session'

    assert create_jws(valid_hash).valid?, 'Should crete valid token'
  end

  test "should update token with new data, iat, and exp" do
    jws, exp, iat = creat_valid_jws

    user = {'id' => 'SomeNewIdentifier'}
    extra_payload = {'something_else_else' => 37}
    jws.update_token(user, extra_payload)
    assert_decode_token jws.token, user: user, exp: jws.exp, iat: jws.iat, extra_payload: extra_payload
    assert_not_equal exp, jws.exp
    assert_not_equal iat, jws.iat
  end

  test "should update token data with new data" do
    jws, exp, iat = creat_valid_jws

    user = {'id' => 'SomeNewIdentifier'}
    extra_payload = {'something_else_else' => 37}
    jws.update_token_data(user, extra_payload)
    assert_decode_token jws.token, user: user, exp: jws.exp, iat: jws.iat, extra_payload: extra_payload
    assert_equal exp, jws.exp
    assert iat < jws.iat, 'iat should be updated to a newer time'
  end

  def create_jws(hash)
    Slots::Slokens.decode(create_token(**hash))
  end

  def valid_hash(**hash)
    {exp: 2.minute.from_now.to_i, iat: 2.minute.ago.to_i, user: {}, session: ''}.merge(hash)
  end

  def creat_valid_jws(exp: 2.minute.from_now.to_i, iat: 2.minute.ago.to_i, session: '')
    user = {'id' => 'SomeIdentifier'}
    extra_payload = {'something_else' => 47}
    jws = create_jws(user: user.as_json, exp: exp, iat: iat, session: session, extra_payload: extra_payload.as_json)
    jws.valid!
    return jws, exp, iat
  end
end

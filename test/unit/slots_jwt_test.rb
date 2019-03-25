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
  test "should encode valid token" do
    user = {'id' => 'SomeIdentifier'}
    extra_payload = {'something_else' => 47}
    jws = Slots::Slokens.encode(user, extra_payload)
    assert_decode_token jws.token, user: user, exp: jws.exp, iat: jws.iat, extra_payload: extra_payload
  end
  test "should encode using config secret" do
    new_secret = 'my0ther$ecr3t'
    Slots.configure do |config|
      config.secret = new_secret
    end
    user = {'id' => 'SomeIdentifier'}
    extra_payload = {'something_else' => 47}

    jws = Slots::Slokens.encode(user, extra_payload)
    assert_decode_token jws.token, user: user, exp: jws.exp, iat: jws.iat, extra_payload: extra_payload, secret: new_secret
  end
  test "should raise error for bad data in yaml" do
    error_raised_with_messege(Errno::ENOENT, "No such file or directory @ rb_sysopen - #{Slots.secret_yaml_file}") do
      Slots.configure do |config|
        config.secret_yaml = true
      end
    end
    error_raised_with_messege(ArgumentError, "Need SECRET") do
      copy_to_config(Rails.root.join('..', 'data', 'missing_secret_secret.yml'))
      Slots.configure do |config|
        config.secret_yaml = true
      end
    end
    error_raised_with_messege(ArgumentError, "Need CREATED_AT") do
      copy_to_config(Rails.root.join('..', 'data', 'missing_created_at_secret.yml'))
      Slots.configure do |config|
        config.secret_yaml = true
      end
    end
    error_raised_with_messege(ArgumentError, "CREATED_AT must be newest to latest") do
      copy_to_config(Rails.root.join('..', 'data', 'out_of_order_secret.yml'))
      Slots.configure do |config|
        config.secret_yaml = true
      end
    end
  end
  test "should encode using correct date from yaml" do
    copy_to_config(Rails.root.join('..', 'data', 'good_secret.yml'))
    Slots.configure do |config|
      config.secret_yaml = true
    end

    hash = {session: '', exp: 1.minute.from_now.to_i, user: {}}
    to_old_iat = 1553294000
    old_iat = 1553294001
    new_iat = 1553295500

    assert_sloken_not_decode create_token('old_secret', iat: to_old_iat, **hash), 'Should not decode to old iat with old secret'
    assert_sloken_not_decode create_token('new_secret', iat: to_old_iat, **hash), 'Should not decode to old iat with new secret'

    assert_sloken_decode create_token('old_secret', iat: old_iat, **hash), 'Should decode old iat with old secret'
    assert_sloken_not_decode create_token('new_secret', iat: old_iat, **hash), 'Should not decode old iat with new secret'

    assert_sloken_not_decode create_token('old_secret', iat: new_iat, **hash), 'Should not decode new iat with old secret'
    assert_sloken_decode create_token('new_secret', iat: new_iat, **hash), 'Should decode new iat with new secret'
  end
  test "should raise error for invalid token" do
    id = 'SomeIdentifier'
    error_raised_with_messege(Slots::InvalidToken, "Invalid Token") do
      Slots::Slokens.decode(create_token(identifier: id, exp: 2.minute.from_now.to_i)).valid!
    end
    error_raised_with_messege(Slots::InvalidToken, "Invalid Token") do
      Slots::Slokens.decode(create_token(identifier: id, iat: 2.minute.ago.to_i)).valid!
    end
    error_raised_with_messege(Slots::InvalidToken, "Invalid Token") do
      Slots::Slokens.decode(create_token(exp: 2.minute.from_now.to_i, iat: 2.minute.ago.to_i)).valid!
    end
    error_raised_with_messege(Slots::InvalidToken, "Invalid Token") do
      Slots::Slokens.decode('FakeToken').valid!
    end
    error_raised_with_messege(Slots::InvalidToken, "Invalid Token") do
      Slots::Slokens.decode("FakeToken.#{Base64.encode64('{]')}.cool").valid!
    end
    error_raised_with_messege(Slots::InvalidToken, "Invalid Token") do
      Slots::Slokens.decode("FakeToken.#{Base64.encode64('[]')}.cool").valid!
    end
    error_raised_with_messege(Slots::InvalidToken, "Invalid Token") do
      Slots::Slokens.decode(create_token(identifier: id, exp: 2.minute.ago.to_i, iat: 2.minute.ago.to_i)).valid!
    end
    error_raised_with_messege(Slots::InvalidToken, "Invalid Token") do
      Slots::Slokens.decode(create_token('my0ther$ecr3t', identifier: id, exp: 2.minute.from_now.to_i, iat: 2.minute.ago.to_i)).valid!
    end
  end

  def creat_old_jws
    exp = 2.minute.from_now.to_i
    iat = 2.minute.ago.to_i
    token = create_token(user: {'id' => 'SomeIdentifier'}.as_json, exp: exp, iat: iat, extra_payload: {'something_else' => 47}.as_json)
    jws = Slots::Slokens.decode(token)
    assert_decode_token jws.token, user: {'id' => 'SomeIdentifier'}, exp: exp, iat: iat, extra_payload: {'something_else' => 47}
    return jws, exp, iat
  end
  test "should update token with new data, iat, and exp" do
    jws, exp, iat = creat_old_jws

    user = {'id' => 'SomeNewIdentifier'}
    extra_payload = {'something_else_else' => 37}
    jws.update_token(user, extra_payload)
    assert_decode_token jws.token, user: user, exp: jws.exp, iat: jws.iat, extra_payload: extra_payload
    assert_not_equal exp, jws.exp
    assert_not_equal iat, jws.iat
  end
  test "should update token data with new data" do
    jws, exp, iat = creat_old_jws

    user = {'id' => 'SomeNewIdentifier'}
    extra_payload = {'something_else_else' => 37}
    jws.update_token_data(user, extra_payload)
    assert_decode_token jws.token, user: user, exp: jws.exp, iat: jws.iat, extra_payload: extra_payload
    assert_equal exp, jws.exp
    assert_equal iat, jws.iat
  end

  def copy_to_config(file)
    FileUtils.cp(file, Slots.secret_yaml_file)
  end

  def assert_sloken_decode(token, message)
    assert(Slots::Slokens.decode(token).valid?, message)
  end

  def assert_sloken_not_decode(token, message)
    assert_not(Slots::Slokens.decode(token).valid?, message)
  end
end

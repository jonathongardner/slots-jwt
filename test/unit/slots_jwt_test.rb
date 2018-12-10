# frozen_string_literal: true

require 'slots_test'
class SlotsJwtTest < SlotsTest
  test "should decode valid token" do
    id = 'SomeIdentifier'
    exp = 1.minute.from_now.to_i
    iat = 1.minute.ago.to_i

    jws = Slots::Slokens.decode(create_token(identifier: id, exp: exp, iat: iat))

    assert jws.valid?, 'Token should be valid'
    assert_equal id, jws.identifier, 'Identifer should be equal to encoded identifier'
    assert_equal exp, jws.exp, 'exp should be equal to encoded exp'
    assert_equal iat, jws.iat, 'iat should be equal to encoded iat'
  end
  test "should encode valid token" do
    id = 'SomeIdentifier'
    extra_payload = {'something_else' => 47}
    jws = Slots::Slokens.encode(id, extra_payload)
    assert_decode_token jws.token, identifier: id, exp: jws.exp, iat: jws.iat, extra_payload: extra_payload
  end
  test "should encode using config secret" do
    new_secret = 'my0ther$ecr3t'
    Slots.configure do |config|
      config.secret = (new_secret)
    end
    id = 'SomeIdentifier'
    extra_payload = {'something_else' => 47}

    jws = Slots::Slokens.encode(id, extra_payload)
    assert_decode_token jws.token, identifier: id, exp: jws.exp, iat: jws.iat, extra_payload: extra_payload, secret: new_secret
  end
  test "should raise error for invalid token" do
    id = 'SomeIdentifier'
    error_raised_with_messege(Slots::InvalidPayload, "Payload is missing objects") do
      Slots::Slokens.decode(create_token(identifier: id, exp: 2.minute.from_now.to_i))
    end
    error_raised_with_messege(Slots::InvalidPayload, "Payload is missing objects") do
      Slots::Slokens.decode(create_token(identifier: id, iat: 2.minute.ago.to_i))
    end
    error_raised_with_messege(Slots::InvalidPayload, "Payload is missing objects") do
      Slots::Slokens.decode(create_token(exp: 2.minute.from_now.to_i, iat: 2.minute.ago.to_i))
    end
    error_raised_with_messege(JWT::DecodeError, "Invalid Payload") do
      Slots::Slokens.decode('FakeToken')
    end
    error_raised_with_messege(JWT::DecodeError, "Invalid Payload") do
      Slots::Slokens.decode("FakeToken.#{Base64.encode64('{]')}.cool")
    end
    error_raised_with_messege(JWT::DecodeError, "Invalid Payload") do
      Slots::Slokens.decode("FakeToken.#{Base64.encode64('[]')}.cool")
    end
    error_raised_with_messege(JWT::ExpiredSignature, "Signature has expired") do
      Slots::Slokens.decode(create_token(identifier: id, exp: 2.minute.ago.to_i, iat: 2.minute.ago.to_i))
    end
    error_raised_with_messege(JWT::VerificationError, "Signature verification raised") do
      Slots::Slokens.decode(create_token('my0ther$ecr3t', identifier: id, exp: 2.minute.from_now.to_i, iat: 2.minute.ago.to_i))
    end
  end
end

# frozen_string_literal: true

require 'slots_test'
class SlotsJwtTest < Slots::Test
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

    jws = Slots::Slokens.encode(id)

    assert_decode_token jws.token, identifier: id, exp: jws.exp, iat: jws.iat
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


  def create_token(secret = 'my$ecr3t', **payload)
    JWT.encode payload, secret, 'HS256'
  end
  def assert_decode_token(token, secret: 'my$ecr3t', identifier: nil, exp: nil, iat: nil)
    begin
      payload_array = JWT.decode token, secret, true, verify_iat: true, algorithm: 'HS256'
      payload = payload_array[0]
      assert_equal identifier, payload['identifier'], 'Identifer should be equal to encoded identifier' if identifier
      assert_equal exp, payload['exp'], 'exp should be equal to encoded exp' if exp
      assert_equal iat, payload['iat'], 'iat should be equal to encoded iat' if iat
    rescue JWT::ExpiredSignature
      assert false, 'Token should not be expired'
    rescue JWT::InvalidIatError
      assert false, 'Token should not have invalid iat'
    rescue JWT::VerificationError
      assert false, 'Token should not have verification error'
    rescue JWT::DecodeError
      assert false, 'Token should not have decoding error'
    end
  end
end

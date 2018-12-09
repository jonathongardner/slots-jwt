# frozen_string_literal: true

require 'test_helper'
module SlotsTestHelper
  def setup
    ENV['SLOT_SECRET'] = 'my$ecr3t'
    Slots.configuration = nil # Reset to default configuration
  end
  def teardown
    ENV['SLOT_SECRET'] = 'my$ecr3t'
    Slots.configuration = nil # Reset to default configuration
  end
  def error_raised_with_messege(error, error_message)
    begin
      yield
    rescue Exception => e
      assert_equal error, e.class, 'Should raise error'
      assert_equal error_message, e.message, 'Should raise error message'
      return
    end
    assert false, "Should raise error #{error}"
  end

  def assert_error_message(message, record, *columns)
    raise 'must pass at least one argument' unless columns.length > 0
    raise 'must all be single objects or symbols' unless columns.all? { |c| c.is_a?(Symbol) || (c.is_a?(Hash) && c.length === 1) }
    columns.each do |c|
      sym, num = c.is_a?(Symbol) ? [c, 0] : [c.keys[0], c.values[0]]
      assert_equal message, record.errors[sym][num], "Should have the correct error message #{sym}: #{record.errors.messages}"
    end
  end

  def assert_number_of_errors(num, record)
    assert_equal num, record.errors.messages.length, "Should have #{num} error messages"
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

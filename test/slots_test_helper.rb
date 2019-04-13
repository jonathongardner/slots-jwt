# frozen_string_literal: true

require 'test_helper'
module SlotsTestHelper
  def setup
    ENV['SLOT_SECRET'] = 'my$ecr3t'
    Slots.configuration = nil # Reset to default configuration
    File.delete(Slots.secret_yaml_file) if File.exist?(Slots.secret_yaml_file)
  end
  def teardown
    ENV['SLOT_SECRET'] = 'my$ecr3t'
    Slots.configuration = nil # Reset to default configuration
    File.delete(Slots.secret_yaml_file) if File.exist?(Slots.secret_yaml_file)
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
  def assert_valid_sloken(token, secret: 'my$ecr3t')
    assert_singleton_method(Slots.configuration, :secret, to_return: secret) do
      assert Slots::Slokens.decode(token), 'Should decode sloken'
    end
  end
  def assert_decode_token(token, secret: 'my$ecr3t', user: nil, exp: nil, iat: nil, session: nil, extra_payload: nil)
    begin
      payload_array = JWT.decode token, secret, true, verify_iat: true, algorithm: 'HS256'
      payload = payload_array[0]
      assert_equal user.as_json.except('created_at', 'updated_at'), payload['user'].except('created_at', 'updated_at'), 'User should be equal to encoded user' if user
      assert_equal exp, payload['exp'], 'exp should be equal to encoded exp' if exp
      assert_equal iat, payload['iat'], 'iat should be equal to encoded iat' if iat
      assert_equal session, payload['session'], 'iat should be equal to encoded session' if session
      assert_equal extra_payload, payload['extra_payload'], 'extra_payload should be equal to encoded extra_payload' if extra_payload
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

  #-------------------Refactored---------------------
  def assert_method(object_to_stub, method, message = nil, to_return: nil, count: 1)
    unbound_method = object_to_stub.instance_method(method)
    method_call_count = 0
    object_to_stub.define_method(method) do |*|
      method_call_count += 1
      to_return
    end
    yield
    object_to_stub.define_method(method, unbound_method)
  end

  def assert_singleton_method(object_to_stub, method, message = nil, to_return: nil, count: 1, with: nil)
    unbound_method = object_to_stub.method(method)
    method_call_count = 0
    passed_options = nil
    object_to_stub.define_singleton_method(method) do |*options|
      passed_options = options
      method_call_count += 1
      to_return
    end
    yield
    object_to_stub.define_singleton_method(method, &unbound_method)
    assert_equal [*with], passed_options, "Method should recieve params #{with}" if with
    assert_equal count, method_call_count, message || "Method should only be called #{count} #{'time'.pluralize(count)}"
  end

  def copy_to_config(file)
    FileUtils.cp(file, Slots.secret_yaml_file)
  end
end

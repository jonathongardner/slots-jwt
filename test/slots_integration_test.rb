# frozen_string_literal: true

require 'slots_test_helper'

class SlotsIntegrationTest < ActionDispatch::IntegrationTest
  include SlotsTestHelper

  def parsed_response
    @parsed_response ||= JSON.parse(response.body)
  end

  def returned_token
    response.headers['authorization'][13..-1]
  end

  def assert_new_token(current_token, **options)
    assert returned_token, 'Should return a token'
    assert current_token != returned_token, 'Should return a new token'
    assert_decode_token returned_token, **options
  end

  def assert_no_new_token
    assert_nil response.headers['authorization'], 'authorization should not be returned if token is not expired'
  end

  def assert_response_error(*keys, error_message)
    assert parsed_response.key?('errors'), 'should be nested in errors'
    errors = parsed_response['errors']
    response_message = errors.dig(*keys)&.first
    assert_equal error_message, response_message, 'Error message should be the same'
  end
end

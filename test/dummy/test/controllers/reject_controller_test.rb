# frozen_string_literal: true

require 'slots_integration_test.rb'
class RejectControllerTest < SlotsIntegrationTest
  include Slots::JWT::Tests

  test "should return enhance_your_calm for reject_action_one_url" do
    # Check that only works
    authorized_get users(:some_great_user), reject_action_one_url
    assert_response :success

    authorized_get users(:another_great_user), reject_action_one_url
    assert_response_enhance_your_calm
    assert_response_error 'my_message', 'Woah caaaallmmm down'
  end

  test "should return enhance_your_calm for reject_action_two_url" do
    # Check that only works
    authorized_get users(:another_great_user), reject_action_two_url
    assert_response :success

    authorized_get users(:some_great_user), reject_action_two_url
    assert_response_enhance_your_calm
    assert_response_error 'my_message', 'Woah caaaallmmm down'
  end

  def assert_response_enhance_your_calm
    assert_equal '420', response.code, "Expected response to be a <420: Enhance Your Calm> but was a <#{response.code}>"
  end
end

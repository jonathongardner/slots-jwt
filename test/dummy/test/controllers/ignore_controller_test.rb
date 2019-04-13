# frozen_string_literal: true

require 'slots_integration_test'
class IgnoreControllerTest < SlotsIntegrationTest
  include Slots::Tests

  test "should return success for some_great_user for ignore_action_one_url" do
    # Check that only works
    authorized_get users(:some_great_user), ignore_action_one_url
    assert_response :success
  end

  test "should return enhance_your_calm for some_great_user for ignore_action_two_url" do
    authorized_get users(:some_great_user), ignore_action_two_url
    assert_response_enhance_your_calm
    assert_response_error 'my_message', 'Woahhhh caaaallmmm down'
  end

  def assert_response_enhance_your_calm
    assert_equal '420', response.code, "Expected response to be a <420: Enhance Your Calm> but was a <#{response.code}>"
  end
end

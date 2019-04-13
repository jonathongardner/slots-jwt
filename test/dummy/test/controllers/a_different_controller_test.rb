# frozen_string_literal: true

require 'slots_integration_test'
class ADifferentControllerTest < SlotsIntegrationTest
  include Slots::Tests

  test "should return success for a_different_valid_user_url when valid token and another_great_user" do
    user = users(:another_great_user)
    authorized_get user, a_different_valid_user_url
    assert_response :success

    assert_no_new_token
  end

  def assert_no_new_token
    assert_nil response.headers['authorization'], 'authorization should not be returned if token is not expired'
  end
end

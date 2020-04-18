# frozen_string_literal: true

require 'slots_integration_test.rb'
class UpdateUserTokenInfoControllerTest < SlotsIntegrationTest
  include Slots::JWT::Tests

  test "should return updated token for user with updated created at action one" do
    get update_user_token_info_action_one_url
    assert_response :success
    assert_no_new_token

    user = users(:another_great_user)
    authorized_get user, update_user_token_info_action_one_url
    assert_response :success
    assert_no_new_token

    updated_user = users(:another_great_user)
    updated_user.created_at = user.created_at + 1.day
    authorized_get updated_user, update_user_token_info_action_one_url
    assert_response :success
    assert_new_token current_token, user: user, session: '', extra_payload: {}


    authorized_get updated_user, update_user_token_info_action_two_url
    assert_response :success
    assert_no_new_token
  end

  test "should return updated token for user with updated updated at action two" do
    # Check that only works
    get update_user_token_info_action_two_url
    assert_response :success

    user = users(:another_great_user)
    authorized_get user, update_user_token_info_action_two_url
    assert_response :success
    assert_no_new_token

    updated_user = users(:another_great_user)
    updated_user.updated_at = user.updated_at + 1.day
    authorized_get updated_user, update_user_token_info_action_two_url
    assert_response :success
    assert_new_token current_token, user: user, session: '', extra_payload: {}

    authorized_get updated_user, update_user_token_info_action_one_url
    assert_response :success
    assert_no_new_token
  end
end

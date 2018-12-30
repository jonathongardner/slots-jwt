# frozen_string_literal: true

require 'slots_integration_test.rb'
class AnotherControllerTest < SlotsIntegrationTest
  include Slots::Tests

  test "should return im_a_teapot for another_valid_user_url when invalid token" do
    get another_valid_user_url
    assert_response_im_a_teapot
    assert_response_error 'my_message', 'Some custom message'
  end

  test "should return im_a_teapot for another_valid_user_url when valid token and invalid user" do
    get another_valid_user_url, headers: token_header(create_token(user: {id: 0}, exp: 1.minute.from_now.to_i, iat: 2.minute.ago.to_i, extra_payload: {}))
    assert_response_im_a_teapot
    assert_response_error 'my_message', 'Some custom message'
  end

  test "should return success for another_valid_user_url when valid token and user" do
    user = users(:some_great_user)
    authorized_get user, another_valid_user_url
    assert_response :success
  end

  test "should return im_a_teapot for another_valid_user_url when valid token and unconfirmed user" do
    user = users(:unconfirmed_user)
    authorized_get user, another_valid_user_url
    assert_response_im_a_teapot
    assert_response_error 'my_message', 'Some custom message'
  end

  test "should return im_a_teapot for valid_token_url when invalid token" do
    get another_valid_token_url
    assert_response_im_a_teapot
    assert_response_error 'my_message', 'Some custom message'
  end

  test "should return success for valid_token_url when valid token and invalid user" do
    get another_valid_token_url, headers: token_header(create_token(user: {id: 0, confirmed: true}, exp: 1.minute.from_now.to_i, iat: 2.minute.ago.to_i, extra_payload: {}))
    assert_response :success
  end

  test "should return success for valid_token_url when valid token and user" do
    user = users(:some_great_user)
    authorized_get user, another_valid_token_url
    assert_response :success
  end

  test "should return im_a_teapot for valid_token_url when valid token and unconfirmed user" do
    user = users(:unconfirmed_user)
    authorized_get user, another_valid_token_url
    assert_response_im_a_teapot
    assert_response_error 'my_message', 'Some custom message'
  end

  def assert_response_im_a_teapot
    assert_equal response.code, '418', "Expected response to be a <418: Im A Teapot> but was a <#{response.code}>"
  end
end

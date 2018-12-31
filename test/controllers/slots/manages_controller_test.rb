# frozen_string_literal: true

require 'slots_integration_test.rb'
module Slots
  class ManagesControllerTest < SlotsIntegrationTest
    include Engine.routes.url_helpers, Slots::Tests

    test "should create user" do
      params = {
        email: 'SomeOneNew@somwhere.com',
        username: 'SomeNewUserName',
        password: 'NewPassword',
        password_confirmation: 'NewPassword'
      }
      assert_difference(['User.count', 'User.email_count']) do
        post create_user_url, params: { user: params}
        assert_response :success
      end
    end

    test "should not create user if confirmation password mismatched" do
      params = {
        email: 'SomeOneNew@somwhere.com',
        username: 'SomeNewUserName',
        password: 'Password1',
        password_confirmation: 'Password2'
      }
      assert_no_difference(['User.count', 'User.email_count']) do
        post create_user_url, params: { user: params}
      end
      assert_response :unprocessable_entity

      assert_response_error 'password_confirmation', "doesn't match Password"
    end

    test "should update user" do
      user = users(:some_great_user)
      params = {
        username: 'SomeNewUserName',
        id: user.id - 1,
        confirmed: false,
        approved: false,
        confirmation_token: 'cool',
      }
      assert_no_difference('User.email_count') do
        authorized_patch user, update_user_url, params: { password: User.pass, user: params }
      end
      assert_response :success

      user.reload
      assert_equal user.username, params[:username], 'Username should be updated'

      assert user.id != params[:id], 'ID should not be updated'
      assert user.confirmed, 'Confirmed should not be updated'
      assert user.approved, 'Approved should not be updated'
      assert user.confirmation_token.blank?, 'Confirmation Token should not be updated'
    end

    test "should update user email" do
      user = users(:some_great_user)
      params = {
        email: 'SomeOneNew@somwhere.com',
      }
      assert_difference('User.email_count') do
        authorized_patch user, update_user_url, params: { password: User.pass, user: params }
      end
      assert_response :success

      user.reload
      assert_equal user.email, params[:email], 'Email should be updated'
      assert_not user.confirmed, 'Email should be unconfirmed since email was changed'
      assert user.confirmation_token.present?, 'Confirmation Token should not be present since email was changed'
    end

    test "should update password for user" do
      user = users(:some_great_user)
      params = {
        password: "New#{User.pass}",
        password_confirmation: "New#{User.pass}",
      }
      authorized_patch user, update_user_url, params: { password: User.pass, user: params }
      assert_response :success

      user.reload
      assert user.authenticate?("New#{User.pass}"), 'Password should not be updated 2'
    end

    test "should not update user if error" do
      user = users(:some_great_user)
      params = {
        email: users(:another_great_user).email, # TODO should setup email when changed to reconfirm email
        username: 'SomeNewUserName',
      }
      authorized_patch user, update_user_url, params: { password: User.pass, user: params }
      assert_response :unprocessable_entity
      assert_response_error 'email', "already taken"

      user.reload
      assert user.email != params[:email], 'Email should be updated'
      assert user.username != params[:username], 'Username should be updated'
    end

    test "should not update if password passed is incorrect" do
      user = users(:some_great_user)
      params = {
        email: 'SomeOneNew@somwhere.com',
      }
      authorized_patch user, update_user_url, params: { password: "SomethingElse", user: params }
      assert_response :unauthorized

      user.reload
      assert user.email != params[:email], 'Email should be updated'
    end

    test "should not update if not logged in" do
      params = {
        email: 'SomeOneNew@somwhere.com',
      }
      put update_user_url, params: { password: User.pass, user: params }
      assert_response :unauthorized
    end

    test "should update confirmation_token" do
      user = users(:unconfirmed_user)
      confirmation_token = user.confirmation_token

      authorized_get user, new_confirmation_token_url
      assert_response :success

      user.reload
      assert user.confirmation_token != confirmation_token, 'Confirmation token should be updated'
    end

    test "should not update confirmation_token if not logged in" do
      get new_confirmation_token_url
      assert_response :unauthorized
    end

    # test "should destroy manage" do
    #   assert_difference('Manage.count', -1) do
    #     delete manage_url(@manage)
    #   end
    #
    #   assert_redirected_to manages_url
    # end
  end
end

# frozen_string_literal: true

require 'slots_test'
class ValidationUserTest < Slots::Test
  test "should not create generic user without logins present" do
    new_user = ValidationUser.new
    assert_not new_user.save, 'saved new user without login'
    assert_error_message "can't be blank", new_user, :email
    assert_number_of_errors 1, new_user

    Slots.configure do |config|
      config.logins = {email: /@/, username: //} # Most inclusive should be last
    end
    assert_not new_user.save, 'saved new user without login'
    assert_error_message "can't be blank", new_user, :email, :username
    assert_number_of_errors 2, new_user
  end

  test "should not create generic user with none unique logins present" do
    new_user = validation_users(:some_great_validation_user).dup
    assert_not new_user.save, 'saved new user without unique login'
    assert_error_message "already taken", new_user, :email
    assert_number_of_errors 1, new_user

    Slots.configure do |config|
      config.logins = {email: /@/, username: //} # Most inclusive should be last
    end
    assert_not new_user.save, 'saved new user without unique login'
    assert_error_message "already taken", new_user, :email, :username
    assert_number_of_errors 2, new_user
  end

  test "should not create generic user with logins not matching login regex part one" do
    Slots.configure do |config|
      config.logins = {email: /@/, username: //} # Most inclusive should be last
    end
    new_user = ValidationUser.new(email: 'notAnEmail', username: 'somethingThatLooksLikeAnEmail@somowhere')

    assert_not new_user.save, 'saved new user with logins that dont match regex'
    assert_error_message "didn't match login criteria", new_user, :email
    assert_error_message "matched email login criteria", new_user, :username
    assert_number_of_errors 2, new_user

    Slots.configure do |config|
      config.login_regex_validations = false
    end

    assert new_user.save, 'did save new user with without login validations'
  end

  test "should not create generic user with logins not matching login regex part two" do
    Slots.configure do |config|
      config.logins = {username: /\A[A-Za-z0-9_\-]+\Z/, email: //} # Most inclusive should be last
    end
    new_user = ValidationUser.new(email: 'notAnEmail', username: 'somethingThatLooksLikeAnEmail@somowhere')

    assert_not new_user.save, 'saved new user with logins that dont match regex'
    assert_error_message "didn't match login criteria", new_user, :username
    assert_error_message "matched username login criteria", new_user, :email
    assert_number_of_errors 2, new_user
  end
end

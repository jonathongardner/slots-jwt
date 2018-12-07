require 'slots_test'

class GenericUserTest < Slots::Test
  test "should sign in user using default email" do
    user = generic_users(:some_great_generic_user)
    assert_equal user, GenericUser.sign_in(user.email, 'password'), 'Should sign in user with correct password'
    assert_not GenericUser.sign_in(user.email, 'not_password'), 'Should not sign in user with wrong password'
    assert_not GenericUser.sign_in('notemail@somweher.com', 'password'), 'Should not sign in user with wrong password'
    assert_not GenericUser.sign_in('', 'password'), 'Should not sign in user that doesnt exist'
    assert_not GenericUser.sign_in(nil, 'password'), 'Should not sign in user that doesnt exist'
  end

  test "should sign in user using config" do
    Slots.configure do |config|
      config.logins = {email: /@/, username: //} # Most inclusive should be last
    end
    great_user = generic_users(:some_great_generic_user)
    assert_equal great_user, GenericUser.sign_in(great_user.email, 'password'), 'Should sign in great user with email'
    assert_equal great_user, GenericUser.sign_in(great_user.username, 'password'), 'Should sign in great user with username'

    bad_user = generic_users(:some_bad_generic_user)
    assert_equal bad_user, GenericUser.sign_in(bad_user.email, 'password'), 'Should sign in bad user with email'
    assert_not GenericUser.sign_in(bad_user.username, 'password'), 'Should not sign in bad user with username because it matches email regex'
  end

  test "should not create generic user without logins present" do
    new_user = GenericUser.new()
    assert_not new_user.save, 'saved new user without login'
    assert_error_message "can't be blank", new_user, {email: 0}
    assert_number_of_errors 1, new_user

    Slots.configure do |config|
      config.logins = {email: /@/, username: //} # Most inclusive should be last
    end
    assert_not new_user.save, 'saved new user without login'
    assert_error_message "can't be blank", new_user, {email: 0}, {username: 0}
    assert_number_of_errors 2, new_user
  end

  test "should not create generic user with none unique logins present" do
    new_user = generic_users(:some_great_generic_user).dup
    assert_not new_user.save, 'saved new user without unique login'
    assert_error_message "already taken", new_user, {email: 0}
    assert_number_of_errors 1, new_user

    Slots.configure do |config|
      config.logins = {email: /@/, username: //} # Most inclusive should be last
    end
    assert_not new_user.save, 'saved new user without unique login'
    assert_error_message "already taken", new_user, {email: 0}, {username: 0}
    assert_number_of_errors 2, new_user
  end

  test "should not create generic user with logins not matching login regex" do
    Slots.configure do |config|
      config.logins = {email: /@/, username: //} # Most inclusive should be last
    end
    new_user = GenericUser.new(email: 'notAnEmail', username: 'somethingThatLooksLikeAnEmail@somowhere')

    assert_not new_user.save, 'saved new user with logins that dont match regex'
    assert_error_message "didn't match login criteria", new_user, {email: 0}
    assert_error_message "matched email longin criteria", new_user, {username: 0}
    assert_number_of_errors 2, new_user

    Slots.configure do |config|
      config.login_regex_validations = false
    end

    assert new_user.save, 'did save new user with without login validations'
  end
end

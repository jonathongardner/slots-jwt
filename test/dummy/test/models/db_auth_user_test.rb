require 'slots_test'

class DbAuthUserTest < Slots::Test
  test "should not create db auth user without password" do
    new_user = DbAuthUser.new(email: 'coolBeans@test.com')
    assert_not new_user.save, 'Saved new user with incorrect info'
    assert_error_message "can't be blank", new_user, {password: 0}
    assert_number_of_errors 1, new_user
  end
  test "should authenticate user using the db" do
    user = db_auth_users(:some_great_db_auth_user)
    assert user.authenticate('password'), 'Should authenticat using bycript'
    assert_not user.authenticate('notapassword'), 'Should not authenticat with wrong password'
  end
  test "sould not return password when using as/to_json" do
    user = db_auth_users(:some_great_db_auth_user)
    assert_not user.as_json.key?('password_digest'), 'Should not have password_digest when converting to json'
    assert_not user.as_json(except: [:email]).key?('email'), 'Should still use as json properties'
  end
end

require 'test_helper'

class ConUserTest < ActiveSupport::TestCase
  test "should authenticate confirmed user" do
    confimred_user = con_users(:confirmed_user)

    assert_not confimred_user.logged_in?, 'Should not be logged_in before validation'
    assert confimred_user.authenticate?(ConUser.pass), 'Should authenticate user with valid passowrd who is confirmed'
    assert confimred_user.logged_in?, 'Should not be logged_in'
  end

  test "should not authenticate unconfirmed user" do
    unconfimred_user = con_users(:not_confirmed_user)

    assert_not unconfimred_user.logged_in?, 'Should not be logged_in before validation'
    assert_not unconfimred_user.authenticate?(ConUser.pass), 'Should not authenticate user with valid passowrd but unconfirmed'
    assert_not unconfimred_user.logged_in?, 'Should not be logged_in'
  end
end

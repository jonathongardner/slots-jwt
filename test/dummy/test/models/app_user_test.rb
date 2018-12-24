# frozen_string_literal: true

require 'slots_test'
class ConUserTest < SlotsTest
  test "should authenticate approved user" do
    approved_user = app_users(:approved_user)

    assert_not approved_user.logged_in?, 'Should not be logged_in before validation'
    assert approved_user.authenticate?(AppUser.pass), 'Should authenticate user with valid passowrd who is approved'
    assert approved_user.logged_in?, 'Should not be logged_in'
  end

  test "should not authenticate unapproved user" do
    unapproved_user = app_users(:not_approved_user)

    assert_not unapproved_user.logged_in?, 'Should not be logged_in before validation'
    assert_not unapproved_user.authenticate?(AppUser.pass), 'Should not authenticate user with valid passowrd but unapproved'
    assert_not unapproved_user.logged_in?, 'Should not be logged_in'
  end
end

# frozen_string_literal: true

require 'slots_test'
class ConUserTest < SlotsTest
  test "should creat user with confirmation token" do
    new_user = ConUser.new(email: 'NewConUser@somewhere.com')

    assert new_user.save, 'Did not save new user with correct info'
    assert_not new_user.confirmed, 'Should not be confirmed on create'
    assert new_user.confirmation_token.present?, 'Should generate random confirmation token'
  end

  test "should confirm token" do
    unconfirmed_user = con_users(:unconfirmed_user)

    assert_not unconfirmed_user.confirm('0OutOf10WontConfirm'), 'should not confirm with incorrect token'
    assert_not unconfirmed_user.confirmed, 'should not be confirm'
    assert unconfirmed_user.confirmation_token.present?, 'Token should be present'

    assert unconfirmed_user.confirm(unconfirmed_user.confirmation_token), 'should confirm with correct token'
    assert unconfirmed_user.confirmed, 'should be confirm'
    assert unconfirmed_user.confirmation_token.blank?, 'Token should be blank after confirmation'
  end

  test "should reset confirmation token" do
    unconfirmed_user = con_users(:unconfirmed_user)
    assert_equal '10OutOf10CanConfirm', unconfirmed_user.confirmation_token

    unconfirmed_user.set_new_confirmation_token
    unconfirmed_user.save!
    assert '10OutOf10CanConfirm' != unconfirmed_user.confirmation_token, 'Token should be updated'
  end

  test "should unconfirm if email changed" do
    confirmed_user = con_users(:confirmed_user)

    assert confirmed_user.confirmed?, 'User should be confirmed'
    assert confirmed_user.confirmation_token.nil?, 'Should not exist since confirmed'

    confirmed_user.update!(email: 'NewEmail@somwehere.com')
    assert_not confirmed_user.confirmed?, 'User should be unconfirmed'
    assert confirmed_user.confirmation_token.present?, 'Token should exist'
  end

  test "should not unconfirm if not email is changed" do
    confirmed_user = con_users(:confirmed_user)

    assert confirmed_user.confirmed?, 'User should be confirmed'
    assert confirmed_user.confirmation_token.nil?, 'Should not exist since confirmed'

    confirmed_user.update!(something_random: 'SomethingRandom')
    assert confirmed_user.confirmed?, 'User should still be confirmed'
    assert confirmed_user.confirmation_token.nil?, 'Should not exist since confirmed'
  end

  test "should authenticate unconfirmed user" do
    unconfirmed_user = con_users(:unconfirmed_user)

    assert_not unconfirmed_user.logged_in?, 'Should not be logged_in before validation'
    assert unconfirmed_user.authenticate?(ConUser.pass), 'Should authenticate user with valid passowrd who is unconfirmed'
    assert unconfirmed_user.logged_in?, 'Should be logged_in'
  end

  test "unconfirmed_user should not be valid" do
    # Check here to to make sure it works by itself
    unconfirmed_user = con_users(:unconfirmed_user)
    assert_not unconfirmed_user.valid_user?, 'unconfirmed_user should not be valid'
    assert unconfirmed_user.valid_user?(confirmed: false), 'unconfirmed_user should be valid if unconfirmed: false'
  end

  test "sould not return confirmation_token when using as/to_json" do
    user = con_users(:unconfirmed_user)
    assert_not user.as_json.key?('confirmation_token'), 'Should not have confirmation_token when converting to json'
    assert_not JSON.parse(user.to_json).key?('confirmation_token'), 'Should not have confirmation_token when converting to json'
    assert_not user.as_json(except: [:email]).key?('email'), 'Should still use as json properties'
  end
end

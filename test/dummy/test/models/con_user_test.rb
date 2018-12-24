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

    assert_not unconfirmed_user.confirm!('0OutOf10WontConfirm'), 'should not confirm with incorrect token'
    assert_not unconfirmed_user.confirmed, 'should not be confirm'
    assert unconfirmed_user.confirmation_token.present?, 'Token should be present'

    assert unconfirmed_user.confirm!(unconfirmed_user.confirmation_token), 'should confirm with correct token'
    assert unconfirmed_user.confirmed, 'should be confirm'
    assert unconfirmed_user.confirmation_token.blank?, 'Token should be blank after confirmation'
  end

  test "should reset confirmation token" do
    unconfirmed_user = con_users(:unconfirmed_user)
    assert_equal '10OutOf10CanConfirm', unconfirmed_user.confirmation_token

    unconfirmed_user.set_new_confirmation_token
    unconfirmed_user.save!
    assert '10OutOf10CanConfirm' != unconfirmed_user.confirmation_token, 'Token should be uodated'
  end
end

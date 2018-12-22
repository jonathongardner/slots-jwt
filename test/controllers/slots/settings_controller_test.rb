# frozen_string_literal: true

require 'slots_integration_test.rb'
module Slots
  class SettingsControllerTest < SlotsIntegrationTest
    include Engine.routes.url_helpers, Slots::Tests

    test "should approve user" do
      to_approve = users(:unapproved_user)
      assert_not to_approve.approved?, 'Should not be approved'

      user = users(:some_great_user)
      assert user.can_approve?(to_approve), 'should be able to approve'

      authorized_get user, approve_url(to_approve.id)
      assert_response :success

      to_approve.reload
      assert to_approve.approved?, 'Should be approved'
    end

    test "should not approve user" do
      to_approve = users(:unapproved_user)
      assert_not to_approve.approved?, 'Should not be approved'

      user = users(:another_great_user)
      assert_not user.can_approve?(to_approve), 'should be able to approve'

      authorized_get user, approve_url(to_approve.id)
      assert_response :forbidden

      to_approve.reload
      assert_not to_approve.approved?, 'Should stil not be approved since the user wasnt allowed to'
    end
  end
end

# frozen_string_literal: true

require 'slots_test.rb'
module Slots
  class SessionTest < SlotsTest
    setup do
      @new_session_hash = {
        jwt_iat: 2.minute.ago.to_i,
        user_id: users(:some_great_user).id
      }
      @new_session = Slots::Session.new(@new_session_hash)
    end
    test "should not save session with missing jwt_iat, or user" do
      new_session = Slots::Session.new
      assert_not new_session.save, 'Save session with columns not present'
      assert_error_message "can't be blank", new_session, :jwt_iat
      assert_error_message 'must exist', new_session, :user
      assert_number_of_errors 2, new_session
    end
    test "should not save session with missing session, jwt_iat, or user" do
      session = slots_sessions(:a_great_session)
      session.session = nil
      assert_not session.save, 'Save session with nil session'
      assert_error_message "can't be blank", session, :session
      assert_number_of_errors 1, session
    end
    test "should not save session without unique session" do
      @new_session.session = slots_sessions(:a_great_session).session
      assert_not @new_session.save, 'Save session without unique session'
      assert_error_message "has already been taken", @new_session, :session
      assert_number_of_errors 1, @new_session
    end
    test "should save session" do
      assert @new_session.save, 'Did not save session with correct info'
      assert @new_session.session.present?, 'session should be present on create'
    end
  end
end

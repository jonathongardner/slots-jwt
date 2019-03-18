# frozen_string_literal: true

require 'slots_test'
class GenericUserTest < SlotsTest
  test "should find user for authentication" do
    user = generic_users(:some_great_generic_user)
    assert_equal user, GenericUser.find_for_authentication(user.email), 'Should find_for_authentication user with correct email'
    assert_empty_user GenericUser.find_for_authentication('notemail@somweher.com'), 'Should not find_for_authentication user with wrong email'
    assert_empty_user GenericUser.find_for_authentication(''), 'Should not find_for_authentication user that doesnt exist'
    assert_empty_user GenericUser.find_for_authentication(nil), 'Should not find_for_authentication user that doesnt exist'
  end

  test "should find_for_authentication user using config" do
    Slots.configure do |config|
      config.logins = {email: /@/, username: //} # Most inclusive should be last
    end
    great_user = generic_users(:some_great_generic_user)
    assert_equal great_user, GenericUser.find_for_authentication(great_user.email), 'Should find_for_authentication great user with email'
    assert_equal great_user, GenericUser.find_for_authentication(great_user.username), 'Should find_for_authentication great user with username'

    bad_user = generic_users(:some_bad_generic_user)
    assert_equal bad_user, GenericUser.find_for_authentication(bad_user.email), 'Should find_for_authentication bad user with email'
    assert_empty_user GenericUser.find_for_authentication(bad_user.username), 'Should not find_for_authentication bad user with username because it matches email regex'
  end

  test "should authenticate user" do
    great_user = generic_users(:some_great_generic_user)

    assert great_user.authenticate?(GenericUser.pass), 'Should authenticate user with valid passowrd'
    assert_not great_user.authenticate?(GenericUser.pass + '_a_little_sometin_sometin'), 'Should not authenticate user with invalid passowrd'
    assert_not GenericUser.new.authenticate?(nil), 'Should not authenticate empty user'
  end

  test "should authenticate user BANG" do
    great_user = generic_users(:some_great_generic_user)

    assert great_user.authenticate!(GenericUser.pass), 'Should authenticate user with valid passowrd'
    assert_raises(Slots::AuthenticationFailed) do
      great_user.authenticate!(GenericUser.pass + '_a_little_sometin_sometin')
    end
    assert_raises(Slots::AuthenticationFailed) do
      GenericUser.new.authenticate!('')
    end
  end

  def assert_empty_user(user, message)
    # need to return empty user for authenticate!
    assert user.new_record?, message
  end
end

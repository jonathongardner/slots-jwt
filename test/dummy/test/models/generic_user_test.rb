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
    Slots::JWT.configure do |config|
      config.logins = {email: /@/, username: //} # Most inclusive should be last
    end
    great_user = generic_users(:some_great_generic_user)
    assert_equal great_user, GenericUser.find_for_authentication(great_user.email), 'Should find_for_authentication great user with email'
    assert_equal great_user, GenericUser.find_for_authentication(great_user.username), 'Should find_for_authentication great user with username'

    bad_user = generic_users(:some_bad_generic_user)
    assert_equal bad_user, GenericUser.find_for_authentication(bad_user.email), 'Should find_for_authentication bad user with email'
    assert_empty_user GenericUser.find_for_authentication(bad_user.username), 'Should not find_for_authentication bad user with username because it matches email regex'
  end

  test "should not authenticate if password blank" do
    great_user = generic_users(:some_great_generic_user)

    assert_singleton_method(great_user, :authenticate, count: 0) do
      assert_not great_user.authenticate?(nil), 'Should not authenticate nil password'
      assert_not great_user.authenticate?(''), 'Should not authenticate blank password'
    end

    assert_singleton_method(great_user, :authenticate, to_return: true) do
      assert great_user.authenticate?('test'), 'Should authenticate none blank password'
    end
  end

  test "should not authenticate user if not persisted" do
    assert_not GenericUser.new.authenticate?('test'), 'Should not authenticate if not saved'

    great_user = generic_users(:some_great_generic_user)
    assert_singleton_method(great_user, :persisted?, to_return: false) do
      assert_not great_user.authenticate?(GenericUser.pass), 'Should not authenticate if not persisted'
    end
    assert great_user.authenticate?(GenericUser.pass), 'Should authenticate user with valid passowrd'
  end

  test "should not authenticate user unless allowed_new_token?" do
    bad_user = generic_users(:some_bad_generic_user)

    assert_singleton_method(bad_user, :authenticate, to_return: true) do
      assert_not bad_user.authenticate?(GenericUser.pass), 'Should not authenticate if reject_new_token'
    end

    great_user = generic_users(:some_great_generic_user)
    assert_singleton_method(great_user, :allowed_new_token?, to_return: false) do
      assert_not great_user.authenticate?(GenericUser.pass), 'Should not authenticate if not allowed_new_token?'
    end
    assert great_user.authenticate?(GenericUser.pass), 'Should authenticate user with valid passowrd'
  end

  test "should authenticate user" do
    great_user = generic_users(:some_great_generic_user)

    assert great_user.authenticate?(GenericUser.pass), 'Should authenticate user with valid passowrd'
    assert_not great_user.authenticate?(GenericUser.pass + '_a_little_sometin_sometin'), 'Should not authenticate user with invalid password'
  end

  test "should authenticate user BANG" do
    great_user = generic_users(:some_great_generic_user)

    assert_singleton_method(great_user, :authenticate?, to_return: true, count: 1) do
      assert great_user.authenticate!('test'), 'Should authenticate user with valid password'
    end

    assert_singleton_method(great_user, :authenticate?, to_return: false, count: 1) do
      assert_raises(Slots::JWT::AuthenticationFailed) do
        great_user.authenticate!(GenericUser.pass)
      end
    end
  end

  def assert_empty_user(user, message)
    # need to return empty user for authenticate!
    assert user.new_record?, message
  end
end

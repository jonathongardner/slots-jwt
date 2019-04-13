# frozen_string_literal: true

require 'slots_test'
class SlotsJwtTest < SlotsTest
  test "should get secret from env" do
    error_raised_with_messege(Slots::InvalidSecret, 'Invalid Secret') do
      Slots.configuration.secret(0)
    end

    assert_equal 'my$ecr3t', Slots.configuration.secret(1)
    assert_equal 'my$ecr3t', Slots.configuration.secret, 'Should use current time if none passed'
  end

  test "should get secret from config" do
    Slots.configure do |config|
      config.secret = 'another_secret'
    end

    error_raised_with_messege(Slots::InvalidSecret, 'Invalid Secret') do
      Slots.configuration.secret(0)
    end

    assert_equal 'another_secret', Slots.configuration.secret(1)
    assert_equal 'another_secret', Slots.configuration.secret, 'Should use current time if none passed'
  end

  test "should get secret from date from yaml" do
    copy_to_config(Rails.root.join('..', 'data', 'good_secret.yml'))
    Slots.configure do |config|
      config.secret_yaml = true
    end

    error_raised_with_messege(Slots::InvalidSecret, 'Invalid Secret') do
      Slots.configuration.secret(1553294000)
    end

    assert_equal 'old_secret', Slots.configuration.secret(1553294001)
    assert_equal 'new_secret', Slots.configuration.secret(1553295500)

    assert_equal 'new_secret', Slots.configuration.secret, 'Should use current time if none passed'
  end

  test "should raise error for bad data in yaml" do
    error_raised_with_messege(Errno::ENOENT, "No such file or directory @ rb_sysopen - #{Slots.secret_yaml_file}") do
      Slots.configure do |config|
        config.secret_yaml = true
      end
    end
    error_raised_with_messege(ArgumentError, "Need SECRET") do
      copy_to_config(Rails.root.join('..', 'data', 'missing_secret_secret.yml'))
      Slots.configure do |config|
        config.secret_yaml = true
      end
    end
    error_raised_with_messege(ArgumentError, "Need CREATED_AT") do
      copy_to_config(Rails.root.join('..', 'data', 'missing_created_at_secret.yml'))
      Slots.configure do |config|
        config.secret_yaml = true
      end
    end
    error_raised_with_messege(ArgumentError, "CREATED_AT must be newest to latest") do
      copy_to_config(Rails.root.join('..', 'data', 'out_of_order_secret.yml'))
      Slots.configure do |config|
        config.secret_yaml = true
      end
    end
  end
end

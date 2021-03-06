# frozen_string_literal: true

require 'test_helper'
require 'generators/slots/model/model_generator'

module Slots
  class ModelGeneratorTest < Rails::Generators::TestCase
    tests ModelGenerator
    destination Rails.root.join('tmp/generators')
    setup :prepare_destination

    # test "generator runs without errors" do
    #   assert_nothing_raised do
    #     run_generator ["arguments"]
    #   end
    # end
  end
end

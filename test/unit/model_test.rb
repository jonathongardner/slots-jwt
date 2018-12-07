require 'slots_test'

class ModelTest < Slots::Test
  test "raise error if extensions not found" do
    error_raised_with_messege(RuntimeError, 'co') do
      raise 'co'
    end
  end
end

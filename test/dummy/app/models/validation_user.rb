# frozen_string_literal: true

class ValidationUser < ApplicationRecord
  include Slots::JWT::GenericValidations
end

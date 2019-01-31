# frozen_string_literal: true

module Slots
  class AuthenticationFailed < StandardError
  end
  class InvalidToken < StandardError
  end
  class AccessDenied < StandardError
  end
  class InvalidSecret < StandardError
  end
end

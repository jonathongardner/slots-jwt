# frozen_string_literal: true

module Slots
  module JWT
    class Engine < ::Rails::Engine
      isolate_namespace Slots::JWT
    end
  end
end

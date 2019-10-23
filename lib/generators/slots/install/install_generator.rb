# frozen_string_literal: true

module Slots
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('templates', __dir__)

    def copy_initializer
      template "slots.rb", "config/initializers/slots.rb"
      template "create_slots_sessions.rb", "db/migrate/#{Time.now.strftime("%Y%m%d%H%M%S")}_create_slots_sessions.rb"
    end

    def add_route
      route "mount Slots::JWT::Engine => '/auth'"
    end
  end
end

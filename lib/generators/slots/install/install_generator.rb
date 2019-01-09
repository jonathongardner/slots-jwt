# frozen_string_literal: true

module Slots
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('templates', __dir__)

    def copy_initializer
      template "slots.rb", "config/initializers/slots.rb"
    end

    def add_route
      route "mount Slots::Engine => '/auth'"
    end
  end
end

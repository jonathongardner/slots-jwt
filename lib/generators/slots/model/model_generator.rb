# frozen_string_literal: true

module Slots
  class ModelGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('templates', __dir__)

    def copy_model
      template "model.rb", "app/models/#{name.underscore}.rb"
      template "model_test.rb", "test/models/#{name.underscore}_test.rb"
      template "create_models.rb", "db/migrate/#{Time.now.strftime("%Y%m%d%H%M%S")}_create_#{name.underscore.pluralize}.rb"
    end

    def set_config
      if name.underscore != 'user'
        file = 'config/initializers/slots.rb'
        config = /\n.+config\.authentication_model = .+/
        gsub_file(file, config, "", verbose: false)
        inject_into_file(file, after: /Slots.configure do .+\n/) do
          "  config.authentication_model = '#{name.classify}'\n"
        end
      end
    end
  end
end

require 'byebug'

namespace :slots do
  desc "Creates or prepends secret in config/lots_secrets.yml"
  task :new_secret do
    FileUtils.touch(Slots.secret_yaml_file)
    secret_keys = YAML.load_file(Slots.secret_yaml_file) || []
    # DO 1 minute from now so has time to restart server
    secret_keys.prepend({'SECRET' => SecureRandom.hex(64), 'CREATED_AT' => 1.minute.from_now.to_i})

     # TODO this might not always work
    slots_initilizer = Rails.root.join('config', 'initializers', 'slots.rb')
    require slots_initilizer if File.file?(slots_initilizer)

    remove_old_secrets = Slots.configuration.session_lifetime.ago.to_i
    secret_keys.reject! { |value| remove_old_secrets > value['CREATED_AT'] }
    File.open(Slots.secret_yaml_file,"w") do |file|
      file.write secret_keys.to_yaml
    end
    Rake::Task["restart"].invoke
  end
  desc "Clears config/lots_secrets.yml"
  task :clear_secrets do
    File.open(Slots.secret_yaml_file,"w") do |file|
      file.write [].to_yaml
    end
  end
end

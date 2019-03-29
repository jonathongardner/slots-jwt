# frozen_string_literal: true

$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "slots/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "slots"
  s.version     = Slots::VERSION
  s.authors     = ["Jonathon Gardner"]
  s.email       = ["TheAppGardner@gmail.com"]
  s.homepage    = "https://github.com/jonathongardner/slots"
  s.summary     = "Token Authentication for Rails using JWT."
  s.description = "Token Authentication for Rails using JWT."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5.0"
  s.add_dependency "bcrypt", "~> 3.1.7"
  s.add_dependency "jwt"

  s.add_development_dependency "sqlite3"
end

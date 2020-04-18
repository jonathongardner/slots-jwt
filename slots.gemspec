# frozen_string_literal: true

$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "slots/jwt/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "slots-jwt"
  s.version     = Slots::JWT::VERSION
  s.authors     = ["Jonathon Gardner"]
  s.email       = ["TheAppGardner@gmail.com"]
  s.homepage    = "https://github.com/jonathongardner/slots-jwt"
  s.summary     = "Token Authentication for Rails using JWT."
  s.description = "Token Authentication for Rails using JWT. Slots is designed to keep JWT stateless"\
    " and minimize database calls. This is done by storing (none sensitive) data in the JWT and populating current_user" \
    " with the JWT data. This allows for things like `current_user.teams` or other assocations to be called on the user."\
    " Unless explicitly told slots will only load the user from the database when creating (or updating an expired) token."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5.0"
  s.add_dependency "bcrypt", "~> 3.1.7"
  s.add_dependency "jwt", "~> 2.1.0"

  s.add_development_dependency "sqlite3"
end
# To release:
# gem build slots.gemspec
# rm gems/slots-jwt-*-1.gem
# mv slots-jwt-*.gem gems/
# gem push gems/slots-jwt-*.gem

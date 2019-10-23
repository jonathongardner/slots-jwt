# Slots
Token authentication solution for rails 5 API. Slots use JSON Web Tokens for authentication and database session for remembering signed in users.

## Getting started
Slots 0.0.4 works with Rails 5. Add this line to your application's Gemfile:

```ruby
gem 'slots-jwt'
```
Then run `bundle install`.

Next create the slots config file and add the routes using:
```console
$ rails generate slots:install
```
This will create `config/initializers/slots.rb` and add the following line to `config/routes.rb`
```ruby
mount Slots::JWT::Engine => "/auth"
```
This will mount all slot routes to `auth/*`.

Next, the following command can be used to generate the authentication model.
```console
$ rails generate slots:model User
```
Any rails accepted name can be used for the model but `User` is the expected default. If a different name is used for the authentication model than it must be defined in the config file for slots (this will automatically be done if the `generate slots` is used).
config/initializers/slots.rb
```ruby
Slots::JWT.configure do |config|
  ...
  config.authentication_model = 'AnotherModel'
  ...
end
```
If you are using a model that has already been created than just add the following with the desired plugins:
```ruby
class MyModel < ApplicationRecord
  ...
  slots :database_authentication
  end
  ...
end
```
And make sure the table has the necessary columns (if using the default setup, that would be email and password_digest). If other methods are desired for authentication like LDAP do not pass `:database_authentication` to slots and add a method `authenticate(password)` in the model. Database Authentication stores a password in the database using Secure Password.

Tokens are expected to be in the header of the request in the following format:
```ruby
'authorization' => 'Bearer token=TOKEN'
```
They are also returned in the header in the same way.

## Usage
To require a user to be authenticated the following methods can be used in the controller.
```ruby
require_login!
```

`require_login!` takes the usual options of a `before_action` (`only`, `except`) and also `load_user`.
The `current_user` is populated with the information from JWT. This can be a problem because the info in the JWT could become out of date; it would not update until the token has expired. If you want to force the user to be reloaded from the database you can call `require_user_load!` or pass `load_user: true` to `require_login!`. Default is not to load the user to help keep the JWT stateless.

NOTE: Before changes can be made to `current_user` user must be reloaded. This can be done using the above method or by `current_user.valid_in_database?`.

WARNING: do not call  `require_login!` twice in one controller. For example if one route, you want with load_user and one without don't do the following, because only the last one will be done.
```ruby
require_login! only: [:action1]
require_login! load_user: true, only: [:action2]
```
This is a limitation on rails `before_action`. In the example above only `action2` will require a login. Instead use the following:
```ruby
require_login! only: [:action1, :action2]
require_user_load! only: [:action2]
```

These method will raise a `Slots::InvalidToken` Error. This error can be caught using the helper method `catch_invalid_token`. If nothing is passed the following will be returned with a unauthorized status:
```
  'errors' => {
    'authentication' => ['invalid or missing token']
  }
```
A custom message or status can be returned using the following:
```ruby
catch_invalid_token(response: {my_message: 'Some custom message'}, status: :im_a_teapot)
```
It is sometimes easier to always require login and explicitly ignore it when needed. To do this add `require_login!` and `catch_invalid_token` to the `ApplicationController`. Then on routes that you do not want to require authentication use the following method.
```ruby
ignore_login!
```
This takes all the same options as `require_login!`.

To not allow a user to sign in the following can be used in the authentication model:
```ruby
class User < ApplicationRecord
  slots :database_authentication

  reject_new_token do
    !self.approved # Return true if they cannot get a new token
  end
end
```
This will not allow unapproved users to get a new token (login or update_session_token).

## Authorization
Sometimes when dealing with authentication you also need authorization. While in most cases you should use another gem to handle this, if it is simple (like an admin or approved user) slots can handle it. Just add the following:
```ruby
class SomeController < ApplicationController
  ...

  reject_token do
    !current_user.admin # Return true to not allow to see resource
  end

  def some_special_action_that_you_must_be_admin_for
  end

  ...
end
```
`reject_token` take the same params as rails `before_action`. This will raise a `Slots::AccessDenied` Error for users not approved for the routes in this controller. To catch this error you can use the helper method `catch_access_denied`. If nothing is passed the following will be returned with a forbidden status:
```
  'errors' => {
    'authorization' => ["can't access"]
  }
```
A custom message or status can be returned using the following:
```ruby
catch_invalid_token(response: {my_message: 'Some custom message'}, status: :im_a_teapot)
```
NOTE: If you want the token to be rejected for all tokens (i.e. require all routes to have an approved user) add the above to the `ApplicationController`. You can then also add more specific requirements to a controller by also adding it in the controller like requiring an admin. To ignore a `reject_token` use `skip_callback!` which again takes the same params as `before_action`.

## Sessions
If sessions are allowed (`session_lifetime` is not nil) `session: true` can be passed along when signing in to receive a session token. A session tokens has a the session id in the payload of the JWT. This is kept in the JWT so the front-end only has to track one token. There are two ways to get a new token after a session token has expired.
  1. The first is by sending the token to `MOUNT_LOCATION/update_session_token`. This method will always return a new token even if the token has not expired. This will return the same information as `sign_in` (user information and with the token in the header).
  2. The second is by adding `update_expired_session_tokens!` (which takes the usual options of a `before_action` `only`, `except`, etc). This method will allow any route to take a valid expired token and it will return a new token in the headers with usual route information in the body. A token will only be returned in the header if the token passed is expired. When using this method a problem can arise were two request are made at the same time with the same expired token. The first request processed would return a new token but the second request would fail because the expired token does not match the information of the session anymore (since it was just updated) and would therefore return unauthorized. To fix this there is a previous jwt lifetime (which defaults to 5 seconds and can be changed in the config). This will allow the previous token to be valid for 5 seconds (or whatever is set in config). If a previous token is sent that is within the previous lifetime it will be a valid token but it will not return a new token (since one was already returned in the earlier request).

## Testing

By adding `include Slots::JWT::Tests` the following methods can be used within minitest, `authorized_get`, `authorized_post`, `authorized_put`, `authorized_patch` and `authorized_delete`. These methods are the same as the usual `get`, ... `delete` but the first param in the method must be the user. For example:
```ruby
authorized_get users(:some_user), some_route_url, params: {one: 'something', ...}, headers: {'info' => 'someInfo', ...}
```

## Configurations
Default configuration:
```ruby
Slots::JWT.configure do |config|
  config.logins = :email
  config.login_regex_validations = true
  config.authentication_model = 'User'
  config.secret = ENV['SLOT_SECRET']
  config.token_lifetime = 1.hour
  config.session_lifetime = 2.weeks
  config.previous_jwt_lifetime = 5.seconds
  config.secret_yaml = false
end
```
- `logins`: this is the column to use for logins. It must be a symbol or a hash with symbol regex pair where the symbol is the column and the regex is when to use it (hash order matters). An example might is
```ruby
  config.logins = {email: /@/, username: //}
```
This would make it if a value for login is passed and it has an @ symbol than check the email column otherwise check the username column.
- `login_regex_validations`: This will require the column for login to match the regex passed and no others before it. So for the example above it would not allow username to contain '@'.
- `authentication_model`: The model used for authentication.
- `secret`: This is the secret used to encode the JWS.
- `token_lifetime`: This is the lifetime of the token, it should be kept short (less than one hour).
- `session_lifetime`: This is the session lifetime, set to nil if you do not want to use sessions.
- `previous_jwt_lifetime`: This is the lifetime of the previous_jwt, for example if two request are sent with an expired token the first one will update the session making the second one invalid (because the iat doesn't match the session). Therefore this is to gives time for all following request to use the new token.
- `secret_yaml`: Set to true to load secret from `config/slots_secrets.yml`. [More](Secret Yaml)

### Secret Yaml
`config/slots_secrets.yml` can be used to store multiple secrets with a date (this way secrets can be updated without invalidating current tokens). The format for the file is:
```yaml
---
- CREATED_AT: EPOCH TIME IN SECONDS
  SECRET: new_secret
- CREATED_AT: EPOCH TIME IN SECONDS
  SECRET: old_secret
...
```
The order should be newer to older secrets. This file can be created/updated manually or using `rake slots:new_secret`. If using `rake slots:new_secret` secrets that are older than session_lifetime will be removed. When updating manually remember to restart the server `rake restart`.

## Routes

All these routes will be mounted at the route used above in `mount Slots::JWT::Engine =>`.

| Route Helper | Route | Token |     |
| ------------ | ----- | ----- | --- |
| `slots.sign_in` | GET/POST `/sign_in` | Does not require Token | This is used to sign in. login and password are expected as params. If the credentials are valid the user is returned with the token in header in the following format: `'authorization' => 'Bearer token=TOKEN'` (same as sending) |
| `slots.sign_out` | DELETE `/sign_out` | Requires Token | This is used to sign out. This will delete the session if one exist for the token. |
| `slots.update_session_token` | GET `/update_session_token` | Requires Token (token can be expired). | This is used to force a new token to be returned from an expired token using the session in the JWT. The token is returned in the same way as sign_in. |


### Why use session token inside a JWS?

Good question, first it's important to talk about some of the reasons (well maybe just one of the reasons) for using JWS:
  - They are stateless. The nice thing is you don't have to go query a database to see if the session exist. Also if you have two different services that don't share a database they can validate the request by having the same secret.

Some of the problems with JWS:
  - Since the tokens are stateless its hard to revoke a token before it expires. In the case of this gem revoking a token is important for signing out. Some solutions suggested are:

| Solutions  | Problems |
| ---------- | -------- |
| Set long expatriation and ignore signing out (Have front end handle it by saving the token if the user wants to stay signed in) | If the token is compromised the token is still valid for X time. You can only revoke it by creating a new secret, which would require all users to get a new tokens. |
| Set long expiration and Store JWS in database | Not stateless. |
| Set long expiration and Blacklist JWS to revoke (or when a user signs out) | Better... but still not stateless. |
| Set short expiration and have a refresher/session token | When user signs out tokens are still valid for X time (which should be short). If the user info is changed (like a user is deactivated) the token is still valid until it expires. If a token with a session is compromised it can be revoked by removing that session (or all sessions if needed). |

The last solution I feel is the best because for most API calls (within the expiration time) the token remains stateless. The downsides can be negligible by setting the expiration time to something small (less than an hour). .

### Why the name???
Last but not least the most important question of them all... why slots??? or better yet slots-jwt??? well I'll start with the first, a slot machine takes tokens... yep that's it, all other authentication names had been taken so this is it. So why slots-jwt? Well hopefully it helps clarify a little what it does but most of all rubygems wouldn't let me name it slots because it was to close to another name..?..? so I added `-jwt`. 


## Contributing


## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

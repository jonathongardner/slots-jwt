# Slots
Token authentication solution for rails 5 API. Slots use JSON Web Tokens for authentication and database session for remembering signed in users.

The current features in slots are:
- Database Authenticatable: stores a password in the database using Secure  Password. If other methods are desired for authentication like LDAP just do not include this module and create a method `authenticate` in the model.
- Approvable: Requires user to be approved before the account is valid.

## Getting started
Slots 0.0.1a works with Rails 5. Add this line to your application's Gemfile:

```ruby
gem 'slots'
```
Then run `bundle install`.

Next create the slots config file and add the routes using:
```console
$ rails generate slots:install
```
This will create `config/initializers/slots.rb` and add the following line to `config/routes.rb`
```ruby
mount Slots::Engine => "/auth"
```
This will mount all slot routes to `auth/*`.

Next, the following command can be used to generate the authentication model.
```console
$ rails generate slots:model User
```
Any rails accepted name can be used for the model but `User` is the expected default. If a different name is used for the authentication model than it must be defined in the config file for slots (this will automatically be done if the `generate slots` is used).
config/initializers/slots.rb
```ruby
Slots.configure do |config|
  ...
  config.authentication_model = 'AnotherModel'
  ...
end
```

## Usage
To require a user to be authenticated the following methods, from the AuthenticationHelper module, can be used in the controller.
```ruby
require_login!
```

`require_login!` takes the usual options `before_action` (`only`, `except`) and also `load_user`.
  - `load_user`: a Boolean. Default is false, which means the `current_user` will be populated with the information from JWT. This can be a problem because the info in the JWT could become out of date; it would not update until the token has expired. If true `current_user` will be reloaded from the database. Default is false to help keep the JWT stateless.

This method will raise a `Slots::InvalidToken` Error. This error can be caught using the helper method `catch_invalid_token`. If nothing is passed the following will be returned with a unauthorized status:
```
  'errors' => {
    'authentication' => ['invalid or missing token']
  }
```
A custom message or status can be returned using the following:
```ruby
catch_invalid_token(response: {errors: {my_message: ['Some custom message']}}, status: :im_a_teapot)
```
It is sometimes easier to always require login and to explicitly ignore it. To do this add `require_login!` and `catch_invalid_token` to the `ApplicationController`. Than on routes that you do not want to require authentication use the following method.
```ruby
ignore_login!
```
This takes all the same options as `require_login!`.

The token is expected to be in the header or the request in the following format:
```ruby
'authorization' => 'Bearer token=TOKEN'
```

## Testing

The following methods can be used within minitest, `authorized_get`, `authorized_post`, `authorized_put`, `authorized_patch` and `authorized_delete`. These methods are the same as the usual `get`, ... `delete` but the first param in the method must be the user. For example:
```ruby
authorized_get users(:some_user), some_route_url, params: {one: 'something', ...}, headers: {'info' => 'someInfo', ...}
```

## Configurations
Default configuration:
```ruby
Slots.configure do |config|
  config.logins = :email
  config.login_regex_validations = true
  config.authentication_model = 'User'
  config.secret = ENV['SLOT_SECRET']
  config.token_lifetime = 1.hour
  config.session_lifetime = 2.weeks
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

## Routes

All these routes will be mounted at the route used above in `mount Slots::Engine =>`.

| Route Helper | Route | Token |     |
| ------------ | ----- | ----- | --- |
| `slots.create_user_url` | POST  `/users` | Does not require Token |  This is for creating a user. |
| `slots.update_user_url` | PUT/PATCH `/users` | Requires Token | This is for editing a user. No ID is needed because a user can only edit their info (`current_user`) |
| `slots.sign_in` | GET/POST `/sign_in` | Does not require Token | This is used to sign in. login and password are expected as params. If the credentials are valid the user is returned with the token. `{'user' => {..., 'token' => SOMETOKEN}}` |
| `slots.sign_out` | DELETE `/sign_out` | Requires Token | This is used to sign out. This will delete the session if one exist for the token. |
| `slots.update_session_token` | GET `/update_session_token` | Requires Token (token can be expired). | This is used get a new token from an expired token using the session in the JWT. The token is returned in the same way as sign_in. |
| `slots.approve` | GET `/approve/:id` | Requires token and a user who can_approve?(:id). | This is for a user like admin to approve new users. |



### Why use session token inside a JWS?

Good question, first it's important to talk about some of the reasons (well maybe just one of the reasons) for using JWS:
  - They are stateless. The nice thing is you don't have to go query a database to see if the session exist. Also if you have two different services that don't share a database they can validate the request by having the same secret.

Some of the problems with JWS:
  - Since the tokens are stateless its hard to revoke a token before it expires. In the case of this gem revoking a token is important for signing out. Some solutions suggested are:

| Solutions  | Problems |
| ---------- | -------- |
| Set long expatriation and ignore signing out (Have front end handle it by saving the token if the user wants to stay signed in) | If the token is compromised the token is still valid for X time. You can only revoke it by creating a new secret, which would require all users to get a new token. |
| Set long expiration and Store JWS in database | Not stateless. |
| Set long expiration and Blacklist JWS to revoke (or when a user signs out) | Better... but still not stateless. |
| Set short expiration and have a refresher/session token | When user signs out tokens are still valid for X time (which should be short). If the user info is changed (like a user is deactivated) the token is still valid until it expires. If a token with a session is compromised it can be revoked by removing that session (or all sessions if needed). |

The last solution I feel is the best because for most API calls (within the expiration time) the token remains stateless. The downsides can be negligible by setting the expiration time to something small (less than an hour). .


## Contributing


## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

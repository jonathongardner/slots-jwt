class GenericUser < ApplicationRecord
  include GenericMethods

  def authenticate(password)
    password == 'password' ? self : false
  end
end

class DbAuthUser < ApplicationRecord
  slots :database_authentication

  def self.pass
    'a_db_password'
  end
end

# frozen_string_literal: true

class CreateDbAuthUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :db_auth_users do |t|
      t.string :email, index: true, unique: true
      t.string :password_digest

      t.timestamps
    end
  end
end

class CreateUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :users do |t|
      t.string :email, index: true, unique: true
      t.string :username, index: true, unqiue: true

      # database_authentication
      t.string :password_digest

      # approvable
      t.boolean :approved, default: false, null: false

      # confirmable
      t.boolean :confirmed, default: false, null: false
      t.string :confirmation_token

      t.timestamps
    end
  end
end

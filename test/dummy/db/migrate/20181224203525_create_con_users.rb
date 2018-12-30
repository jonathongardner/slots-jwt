class CreateConUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :con_users do |t|
      t.string :email, index: true, unique: true
      t.boolean :confirmed, default: false, null: false
      t.string :confirmation_token

      t.string :something_random
      t.timestamps
    end
  end
end

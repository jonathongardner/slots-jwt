class CreateTokenUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :token_users do |t|
      t.string :email

      t.timestamps
    end
  end
end

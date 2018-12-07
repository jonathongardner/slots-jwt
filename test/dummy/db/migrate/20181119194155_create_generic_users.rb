class CreateGenericUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :generic_users do |t|
      t.string :email, index: true, unique: true
      t.string :username, index: true, unqiue: true

      t.timestamps
    end
  end
end

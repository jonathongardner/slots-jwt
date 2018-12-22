class CreateAppUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :app_users do |t|
      t.string :email, index: true, unique: true
      t.boolean :approved, default: false, null: false

      t.timestamps
    end
  end
end

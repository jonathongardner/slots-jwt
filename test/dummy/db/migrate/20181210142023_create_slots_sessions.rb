class CreateSlotsSessions < ActiveRecord::Migration[5.2]
  def change
    create_table :slots_sessions do |t|
      t.string :session, length: 128
      t.bigint :jwt_iat
      t.bigint :user_id, index: true

      t.timestamps
    end
    add_index :slots_sessions, :session, unique: true
  end
end

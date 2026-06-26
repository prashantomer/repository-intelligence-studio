class CreateConversations < ActiveRecord::Migration[8.1]
  def change
    create_table :conversations do |t|
      t.references :repository, null: false, foreign_key: true
      t.bigint :user_id
      t.string :title, null: false

      t.timestamps
    end

    add_index :conversations, [:repository_id, :created_at]
    add_index :conversations, :user_id
  end
end

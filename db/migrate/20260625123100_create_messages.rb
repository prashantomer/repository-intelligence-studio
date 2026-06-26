class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: true
      t.string :role, null: false
      t.text :content, null: false
      t.jsonb :cites_json, null: false, default: []
      t.integer :prompt_tokens, null: false, default: 0
      t.integer :completion_tokens, null: false, default: 0

      t.timestamps
    end

    add_index :messages, [:conversation_id, :created_at]
    add_index :messages, :role
  end
end

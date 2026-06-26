class AddResponseStateToMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :messages, :response_state, :string, null: false, default: "completed"
    add_index :messages, :response_state
  end
end

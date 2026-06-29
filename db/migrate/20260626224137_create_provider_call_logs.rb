class CreateProviderCallLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :provider_call_logs do |t|
      t.references :repository, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :operation_type, null: false
      t.string :model, null: false
      t.string :status, null: false
      t.string :endpoint
      t.text :error_message
      t.jsonb :request_metadata, null: false, default: {}
      t.jsonb :response_metadata, null: false, default: {}
      t.integer :prompt_tokens, null: false, default: 0
      t.integer :completion_tokens, null: false, default: 0
      t.integer :total_tokens, null: false, default: 0
      t.integer :latency_ms, null: false, default: 0
      t.decimal :estimated_cost_usd, precision: 12, scale: 6

      t.timestamps
    end

    add_index :provider_call_logs, :created_at
    add_index :provider_call_logs, [:user_id, :created_at]
    add_index :provider_call_logs, [:repository_id, :created_at]
    add_index :provider_call_logs, [:provider, :operation_type, :status], name: "index_provider_call_logs_on_provider_operation_status"
  end
end

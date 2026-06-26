class CreateAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_logs do |t|
      t.references :repository, null: false, foreign_key: true
      t.string :auditable_type
      t.bigint :auditable_id
      t.string :event, null: false
      t.text :message
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :audit_logs, :event
    add_index :audit_logs, [:auditable_type, :auditable_id]
  end
end

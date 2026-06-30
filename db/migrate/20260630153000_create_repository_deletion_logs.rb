class CreateRepositoryDeletionLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :repository_deletion_logs do |t|
      t.bigint :deleted_repository_id, null: false
      t.references :user, foreign_key: true
      t.string :name, null: false
      t.string :github_url, null: false
      t.string :provider
      t.string :visibility
      t.string :default_branch
      t.string :tracked_branch
      t.string :status
      t.string :last_commit_sha
      t.datetime :last_ingested_at
      t.string :assistant_provider
      t.string :assistant_model
      t.string :embedding_provider
      t.string :embedding_model
      t.datetime :deleted_at, null: false
      t.string :deletion_reason, null: false, default: "user_requested"
      t.jsonb :summary_json, null: false, default: {}

      t.timestamps
    end

    add_index :repository_deletion_logs, :deleted_repository_id, unique: true
    add_index :repository_deletion_logs, :deleted_at
    add_index :repository_deletion_logs, :github_url
  end
end

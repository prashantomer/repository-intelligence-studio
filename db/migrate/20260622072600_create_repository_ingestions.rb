class CreateRepositoryIngestions < ActiveRecord::Migration[8.1]
  def change
    create_table :repository_ingestions do |t|
      t.references :repository, null: false, foreign_key: true
      t.string :branch_name, null: false
      t.string :commit_sha
      t.string :status, null: false, default: "pending"
      t.datetime :started_at
      t.datetime :finished_at
      t.text :error_message
      t.bigint :triggered_by_id

      t.timestamps
    end

    add_index :repository_ingestions, :status
    add_index :repository_ingestions, [:repository_id, :created_at]
    add_index :repository_ingestions, [:repository_id, :branch_name]
    add_index :repository_ingestions, :triggered_by_id
  end
end

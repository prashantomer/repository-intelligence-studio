class CreateRepositories < ActiveRecord::Migration[8.1]
  def change
    create_table :repositories do |t|
      t.string :name, null: false
      t.string :github_url, null: false
      t.string :default_branch, null: false
      t.string :tracked_branch, null: false
      t.string :status, null: false, default: "pending"
      t.string :visibility, null: false, default: "public"
      t.string :provider, null: false, default: "github"
      t.datetime :last_ingested_at
      t.string :last_commit_sha

      t.timestamps
    end

    add_index :repositories, :github_url, unique: true
    add_index :repositories, :status
    add_index :repositories, :provider
  end
end

class CreateCodeFiles < ActiveRecord::Migration[8.1]
  def change
    create_table :code_files do |t|
      t.references :repository, null: false, foreign_key: true
      t.string :path, null: false
      t.string :language, null: false
      t.string :content_hash, null: false
      t.integer :size_bytes, null: false, default: 0

      t.timestamps
    end

    add_index :code_files, [:repository_id, :path], unique: true
    add_index :code_files, :language
  end
end

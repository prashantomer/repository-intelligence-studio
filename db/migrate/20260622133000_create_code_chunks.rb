class CreateCodeChunks < ActiveRecord::Migration[8.1]
  def change
    create_table :code_chunks do |t|
      t.references :repository, null: false, foreign_key: true
      t.references :code_file, null: false, foreign_key: true
      t.references :entity, foreign_key: true
      t.string :chunk_type, null: false
      t.text :chunk_text, null: false
      t.integer :start_line, null: false
      t.integer :end_line, null: false
      t.integer :token_count, null: false, default: 0

      t.timestamps
    end

    add_index :code_chunks, [:repository_id, :chunk_type]
    add_index :code_chunks, [:code_file_id, :start_line, :end_line], name: "idx_code_chunks_file_lines"
  end
end

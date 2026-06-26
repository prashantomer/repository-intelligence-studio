class CreateEntities < ActiveRecord::Migration[8.1]
  def change
    create_table :entities do |t|
      t.references :repository, null: false, foreign_key: true
      t.references :code_file, null: false, foreign_key: true
      t.string :entity_type, null: false
      t.string :name, null: false
      t.string :namespace
      t.string :signature
      t.jsonb :metadata_json, null: false, default: {}

      t.timestamps
    end

    add_index :entities, [:repository_id, :entity_type]
    add_index :entities, [:repository_id, :name]
  end
end

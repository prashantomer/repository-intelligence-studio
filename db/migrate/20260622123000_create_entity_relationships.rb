class CreateEntityRelationships < ActiveRecord::Migration[8.1]
  def change
    create_table :entity_relationships do |t|
      t.references :repository, null: false, foreign_key: true
      t.references :source_entity, null: false, foreign_key: { to_table: :entities }
      t.references :target_entity, null: false, foreign_key: { to_table: :entities }
      t.string :relationship_type, null: false

      t.timestamps
    end

    add_index :entity_relationships, [:repository_id, :relationship_type]
    add_index :entity_relationships, [:source_entity_id, :target_entity_id, :relationship_type], unique: true, name: "idx_entity_relationship_uniqueness"
  end
end

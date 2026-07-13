class CreateDependencyEdges < ActiveRecord::Migration[8.1]
  def change
    create_table :dependency_edges do |t|
      t.references :repository, null: false, foreign_key: true
      t.string :source_type, null: false
      t.bigint :source_id, null: false
      t.string :target_type, null: false
      t.bigint :target_id, null: false
      t.string :edge_type, null: false
      t.decimal :confidence, precision: 4, scale: 2, null: false, default: 0.5

      t.timestamps
    end

    add_index :dependency_edges, [:repository_id, :source_type, :source_id], name: "index_dependency_edges_on_repository_and_source"
    add_index :dependency_edges, [:repository_id, :target_type, :target_id], name: "index_dependency_edges_on_repository_and_target"
    add_index :dependency_edges, [:repository_id, :edge_type], name: "index_dependency_edges_on_repository_and_edge_type"
    add_index :dependency_edges,
              [:repository_id, :source_type, :source_id, :target_type, :target_id, :edge_type],
              unique: true,
              name: "index_dependency_edges_on_repository_source_target_and_type"
  end
end

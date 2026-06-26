class AddForceRebuildToRepositoryIngestions < ActiveRecord::Migration[8.1]
  def change
    add_column :repository_ingestions, :force_rebuild, :boolean, null: false, default: false
    add_index :repository_ingestions, :force_rebuild
  end
end

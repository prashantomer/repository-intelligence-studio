class AddIndexedEmbeddingSettingsToRepositories < ActiveRecord::Migration[8.0]
  def change
    change_table :repositories, bulk: true do |t|
      t.string :indexed_embedding_provider
      t.string :indexed_embedding_model
    end
  end
end

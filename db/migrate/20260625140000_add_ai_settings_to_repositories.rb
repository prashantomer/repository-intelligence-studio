class AddAiSettingsToRepositories < ActiveRecord::Migration[8.0]
  def change
    change_table :repositories, bulk: true do |t|
      t.string :assistant_provider, null: false, default: "local"
      t.string :assistant_model, null: false, default: "grounded-local"
      t.string :embedding_provider, null: false, default: "local"
      t.string :embedding_model, null: false, default: "deterministic-v1"
      t.string :ollama_base_url, null: false, default: "http://127.0.0.1:11434"
    end
  end
end

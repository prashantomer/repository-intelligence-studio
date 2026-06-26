class CreateUsersAndAssignRepositoryOwners < ActiveRecord::Migration[8.0]
  class MigrationRepository < ApplicationRecord
    self.table_name = "repositories"
  end

  def up
    create_table :users do |t|
      t.string :name, null: false
      t.string :email
      t.string :assistant_provider, null: false, default: "local"
      t.string :assistant_model, null: false, default: "grounded-local"
      t.string :embedding_provider, null: false, default: "local"
      t.string :embedding_model, null: false, default: "deterministic-v1"
      t.string :ollama_base_url, null: false, default: "http://127.0.0.1:11434"
      t.timestamps
    end

    add_reference :repositories, :user, foreign_key: true

    default_user_id = create_default_user
    MigrationRepository.reset_column_information
    MigrationRepository.update_all(user_id: default_user_id)
    change_column_null :repositories, :user_id, false
  end

  def down
    remove_reference :repositories, :user, foreign_key: true
    drop_table :users
  end

  private

  def create_default_user
    sample_repository = select_one(<<~SQL.squish)
      SELECT assistant_provider, assistant_model, embedding_provider, embedding_model, ollama_base_url
      FROM repositories
      ORDER BY id ASC
      LIMIT 1
    SQL

    values = {
      name: "Default User",
      email: "default@example.local",
      assistant_provider: sample_repository&.fetch("assistant_provider", nil).presence || "local",
      assistant_model: sample_repository&.fetch("assistant_model", nil).presence || "grounded-local",
      embedding_provider: sample_repository&.fetch("embedding_provider", nil).presence || "local",
      embedding_model: sample_repository&.fetch("embedding_model", nil).presence || "deterministic-v1",
      ollama_base_url: sample_repository&.fetch("ollama_base_url", nil).presence || "http://127.0.0.1:11434",
      created_at: Time.current,
      updated_at: Time.current
    }

    connection.insert(
      build_insert_sql(values),
      "Create default user"
    )
  end

  def build_insert_sql(values)
    <<~SQL.squish
      INSERT INTO users
      (name, email, assistant_provider, assistant_model, embedding_provider, embedding_model, ollama_base_url, created_at, updated_at)
      VALUES
      (#{quoted(values[:name])}, #{quoted(values[:email])}, #{quoted(values[:assistant_provider])}, #{quoted(values[:assistant_model])},
       #{quoted(values[:embedding_provider])}, #{quoted(values[:embedding_model])}, #{quoted(values[:ollama_base_url])},
       #{quoted(values[:created_at])}, #{quoted(values[:updated_at])})
    SQL
  end

  def quoted(value)
    connection.quote(value)
  end
end

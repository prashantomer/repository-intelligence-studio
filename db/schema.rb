# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_06_26_113000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "vector"

  create_table "audit_logs", force: :cascade do |t|
    t.bigint "auditable_id"
    t.string "auditable_type"
    t.datetime "created_at", null: false
    t.string "event", null: false
    t.text "message"
    t.jsonb "metadata", default: {}, null: false
    t.bigint "repository_id", null: false
    t.datetime "updated_at", null: false
    t.index ["auditable_type", "auditable_id"], name: "index_audit_logs_on_auditable_type_and_auditable_id"
    t.index ["event"], name: "index_audit_logs_on_event"
    t.index ["repository_id"], name: "index_audit_logs_on_repository_id"
  end

# Could not dump table "code_chunks" because of following StandardError
#   Unknown type 'vector(1024)' for column 'embedding'


  create_table "code_files", force: :cascade do |t|
    t.string "content_hash", null: false
    t.datetime "created_at", null: false
    t.string "language", null: false
    t.string "path", null: false
    t.bigint "repository_id", null: false
    t.integer "size_bytes", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["language"], name: "index_code_files_on_language"
    t.index ["repository_id", "path"], name: "index_code_files_on_repository_id_and_path", unique: true
    t.index ["repository_id"], name: "index_code_files_on_repository_id"
  end

  create_table "conversations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "repository_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["repository_id", "created_at"], name: "index_conversations_on_repository_id_and_created_at"
    t.index ["repository_id"], name: "index_conversations_on_repository_id"
    t.index ["user_id"], name: "index_conversations_on_user_id"
  end

  create_table "entities", force: :cascade do |t|
    t.bigint "code_file_id", null: false
    t.datetime "created_at", null: false
    t.string "entity_type", null: false
    t.jsonb "metadata_json", default: {}, null: false
    t.string "name", null: false
    t.string "namespace"
    t.bigint "repository_id", null: false
    t.string "signature"
    t.datetime "updated_at", null: false
    t.index ["code_file_id"], name: "index_entities_on_code_file_id"
    t.index ["repository_id", "entity_type"], name: "index_entities_on_repository_id_and_entity_type"
    t.index ["repository_id", "name"], name: "index_entities_on_repository_id_and_name"
    t.index ["repository_id"], name: "index_entities_on_repository_id"
  end

  create_table "entity_relationships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "relationship_type", null: false
    t.bigint "repository_id", null: false
    t.bigint "source_entity_id", null: false
    t.bigint "target_entity_id", null: false
    t.datetime "updated_at", null: false
    t.index ["repository_id", "relationship_type"], name: "idx_on_repository_id_relationship_type_9c3962c979"
    t.index ["repository_id"], name: "index_entity_relationships_on_repository_id"
    t.index ["source_entity_id", "target_entity_id", "relationship_type"], name: "idx_entity_relationship_uniqueness", unique: true
    t.index ["source_entity_id"], name: "index_entity_relationships_on_source_entity_id"
    t.index ["target_entity_id"], name: "index_entity_relationships_on_target_entity_id"
  end

  create_table "messages", force: :cascade do |t|
    t.jsonb "cites_json", default: [], null: false
    t.integer "completion_tokens", default: 0, null: false
    t.text "content", null: false
    t.bigint "conversation_id", null: false
    t.datetime "created_at", null: false
    t.integer "prompt_tokens", default: 0, null: false
    t.string "response_state", default: "completed", null: false
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id", "created_at"], name: "index_messages_on_conversation_id_and_created_at"
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["response_state"], name: "index_messages_on_response_state"
    t.index ["role"], name: "index_messages_on_role"
  end

  create_table "repositories", force: :cascade do |t|
    t.string "assistant_model", default: "grounded-local", null: false
    t.string "assistant_provider", default: "local", null: false
    t.datetime "created_at", null: false
    t.string "default_branch", null: false
    t.string "embedding_model", default: "deterministic-v1", null: false
    t.string "embedding_provider", default: "local", null: false
    t.string "github_url", null: false
    t.string "indexed_embedding_model"
    t.string "indexed_embedding_provider"
    t.string "last_commit_sha"
    t.datetime "last_ingested_at"
    t.string "name", null: false
    t.string "ollama_base_url", default: "http://127.0.0.1:11434", null: false
    t.string "provider", default: "github", null: false
    t.string "status", default: "pending", null: false
    t.string "tracked_branch", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.string "visibility", default: "public", null: false
    t.index ["github_url"], name: "index_repositories_on_github_url", unique: true
    t.index ["provider"], name: "index_repositories_on_provider"
    t.index ["status"], name: "index_repositories_on_status"
    t.index ["user_id"], name: "index_repositories_on_user_id"
  end

  create_table "repository_ingestions", force: :cascade do |t|
    t.string "branch_name", null: false
    t.string "commit_sha"
    t.datetime "created_at", null: false
    t.text "error_message"
    t.datetime "finished_at"
    t.boolean "force_rebuild", default: false, null: false
    t.bigint "repository_id", null: false
    t.datetime "started_at"
    t.string "status", default: "pending", null: false
    t.bigint "triggered_by_id"
    t.datetime "updated_at", null: false
    t.index ["force_rebuild"], name: "index_repository_ingestions_on_force_rebuild"
    t.index ["repository_id", "branch_name"], name: "index_repository_ingestions_on_repository_id_and_branch_name"
    t.index ["repository_id", "created_at"], name: "index_repository_ingestions_on_repository_id_and_created_at"
    t.index ["repository_id"], name: "index_repository_ingestions_on_repository_id"
    t.index ["status"], name: "index_repository_ingestions_on_status"
    t.index ["triggered_by_id"], name: "index_repository_ingestions_on_triggered_by_id"
  end

  create_table "repository_routes", force: :cascade do |t|
    t.string "action_name"
    t.string "controller_name"
    t.datetime "created_at", null: false
    t.string "http_method", null: false
    t.string "path", null: false
    t.bigint "repository_id", null: false
    t.datetime "updated_at", null: false
    t.index ["repository_id", "path"], name: "index_repository_routes_on_repository_id_and_path"
    t.index ["repository_id"], name: "index_repository_routes_on_repository_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "assistant_model", default: "grounded-local", null: false
    t.string "assistant_provider", default: "local", null: false
    t.datetime "created_at", null: false
    t.string "email"
    t.string "embedding_model", default: "deterministic-v1", null: false
    t.string "embedding_provider", default: "local", null: false
    t.string "name", null: false
    t.string "ollama_base_url", default: "http://127.0.0.1:11434", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "audit_logs", "repositories"
  add_foreign_key "code_chunks", "code_files"
  add_foreign_key "code_chunks", "entities"
  add_foreign_key "code_chunks", "repositories"
  add_foreign_key "code_files", "repositories"
  add_foreign_key "conversations", "repositories"
  add_foreign_key "entities", "code_files"
  add_foreign_key "entities", "repositories"
  add_foreign_key "entity_relationships", "entities", column: "source_entity_id"
  add_foreign_key "entity_relationships", "entities", column: "target_entity_id"
  add_foreign_key "entity_relationships", "repositories"
  add_foreign_key "messages", "conversations"
  add_foreign_key "repositories", "users"
  add_foreign_key "repository_ingestions", "repositories"
  add_foreign_key "repository_routes", "repositories"
end

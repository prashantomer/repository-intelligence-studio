require "rails_helper"

RSpec.describe Repositories::DestroyService, type: :service do
  let!(:user) { User.create!(name: "User", email: "user@example.test") }
  let!(:repository) do
    Repository.create!(
      user: user,
      name: "FinTrack",
      github_url: "https://github.com/example/fintrack",
      default_branch: "main",
      tracked_branch: "main",
      status: :completed,
      visibility: :public_repo,
      provider: :github
    )
  end
  let!(:ingestion) do
    repository.repository_ingestions.create!(branch_name: "main", status: :completed)
  end
  let!(:code_file) { repository.code_files.create!(path: "app/models/user.rb", language: "ruby", content_hash: "abc", size_bytes: 10) }
  let!(:entity) { repository.entities.create!(code_file: code_file, name: "User", entity_type: "class", signature: "class User") }
  let!(:code_chunk) { repository.code_chunks.create!(code_file: code_file, chunk_text: "class User; end", start_line: 1, end_line: 1, chunk_type: "entity") }
  let!(:route) { repository.repository_routes.create!(path: "/users", http_method: "GET", controller_name: "UsersController", action_name: "index") }
  let!(:relationship) { repository.entity_relationships.create!(source_entity: entity, target_entity: entity, relationship_type: "references") }
  let!(:edge) { repository.dependency_edges.create!(source_type: "Entity", source_id: entity.id, target_type: "Entity", target_id: entity.id, edge_type: "references") }
  let!(:conversation) { repository.conversations.create!(title: "Thread", user: user) }
  let!(:message) { conversation.messages.create!(role: :user, content: "hello") }
  let!(:provider_log) { repository.provider_call_logs.create!(user: user, provider: "ollama", model: "m1", operation_type: :assistant, status: :success) }
  let!(:impact_report) { repository.impact_reports.create!(query: "User", generated_at: Time.current, result_json: { "entity_name" => "User" }) }
  let!(:audit_log) { repository.audit_logs.create!(event: "repository.test", message: "hello", metadata: {}) }

  it "deletes the repository and writes a deletion log" do
    result = described_class.call(repository: repository)

    expect(result).to be_success
    expect(Repository.exists?(repository.id)).to be(false)
    expect(RepositoryDeletionLog.where(deleted_repository_id: repository.id).count).to eq(1)

    log = RepositoryDeletionLog.find_by!(deleted_repository_id: repository.id)
    expect(log.name).to eq("FinTrack")
    expect(log.summary["ingestion_count"]).to eq(1)
    expect(log.summary["message_count"]).to eq(1)
    expect(log.summary["impact_report_count"]).to eq(1)
  end

  it "works when an active ingestion exists" do
    ingestion.update!(status: :parsing)

    result = described_class.call(repository: repository)

    expect(result).to be_success
    expect(RepositoryDeletionLog.find_by!(deleted_repository_id: repository.id).summary["active_ingestion_present"]).to eq(true)
  end
end

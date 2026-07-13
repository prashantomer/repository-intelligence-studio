require "rails_helper"

RSpec.describe "RepositoryDeletionLogs", type: :request do
  it "renders the deletion log index" do
    get repository_deletion_logs_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Repository Deletion Logs")
  end
end

require "rails_helper"

RSpec.describe "Repositories", type: :request do
  describe "GET /repositories" do
    it "renders the repository index" do
      get repositories_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Repositories")
    end
  end

  describe "POST /repositories" do
    it "creates a repository and redirects to the show page" do
      allow(RepositoryIngestionJob).to receive(:perform_later)

      expect do
        post repositories_path, params: {
          repository: {
            name: "eka",
            github_url: "https://github.com/example/eka",
            default_branch: "main",
            tracked_branch: ""
          }
        }
      end.to change(Repository, :count).by(1)

      repository = Repository.order(created_at: :desc).first

      expect(response).to redirect_to(repository_path(repository))
      expect(repository.tracked_branch).to eq("main")
      expect(repository.repository_ingestions.count).to eq(1)
    end
  end

  describe "DELETE /repositories/:id" do
    let!(:repository) do
      Repository.create!(
        user: User.order(:id).first_or_create!(name: "Default User", email: "default@example.local"),
        name: "eka",
        github_url: "https://github.com/example/delete-me",
        default_branch: "main",
        tracked_branch: "main",
        status: :completed,
        visibility: :public_repo,
        provider: :github
      )
    end

    it "deletes the repository and redirects to index" do
      expect do
        delete repository_path(repository)
      end.to change(Repository, :count).by(-1)
        .and change(RepositoryDeletionLog, :count).by(1)

      expect(response).to redirect_to(repositories_path)
      follow_redirect!
      expect(response.body).to include("Repository deleted permanently")
    end
  end
end

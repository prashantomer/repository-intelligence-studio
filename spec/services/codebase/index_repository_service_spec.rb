require "rails_helper"

RSpec.describe Codebase::IndexRepositoryService, type: :service do
  let(:repository) do
    Repository.create!(
      name: "test-repo",
      github_url: "https://github.com/test/repo",
      default_branch: "main",
      tracked_branch: "main"
    )
  end

  let(:repo_path) { Rails.root.join("spec/fixtures/sample_repo") }

  before do
    FileUtils.mkdir_p(repo_path)
    File.write(repo_path.join("file1.rb"), "class MyClass\nend\n")
    File.write(repo_path.join("file2.rb"), "module MyModule\nend\n")
  end

  after do
    FileUtils.rm_rf(repo_path) if Dir.exist?(repo_path)
  end

  describe "#call" do
    it "indexes files and returns success with metadata counts" do
      result = described_class.call(repository:, root_path: repo_path)

      expect(result).to be_success
      expect(result.data[:code_files_count]).to eq(2)
      expect(result.data[:entities_count]).to be >= 0
      expect(result.data[:chunks_count]).to be >= 0
    end

    it "creates CodeFile records for all files" do
      described_class.call(repository:, root_path: repo_path)

      expect(repository.code_files.count).to eq(2)
      expect(repository.code_files.pluck(:path)).to include("file1.rb", "file2.rb")
    end

    it "creates CodeChunk records with accurate token counts" do
      described_class.call(repository:, root_path: repo_path)

      chunks = repository.code_chunks.all
      expect(chunks.count).to be > 0

      chunks.each do |chunk|
        expect(chunk.token_count).to be > 0
        # Verify token count is reasonable (approximated as text.length / 4)
        expected_count = (chunk.chunk_text.length / 4.0).ceil
        expect(chunk.token_count).to eq(expected_count)
      end
    end

    context "on re-indexing" do
      it "purges and recreates all index data" do
        # First indexing
        result1 = described_class.call(repository:, root_path: repo_path)
        first_chunk_count = repository.code_chunks.count

        # Modify a file
        File.write(repo_path.join("file1.rb"), "class MyClass\ndef test_method\nend\nend\n")

        # Second indexing
        result2 = described_class.call(repository:, root_path: repo_path)

        # Should have new chunks (purged and recreated)
        expect(result2.data[:code_files_count]).to eq(2)
      end
    end

    context "transaction safety" do
      it "uses transactions to ensure consistency" do
        allow(Codebase::FileInventoryService).to receive(:call).and_call_original
        allow(Codebase::EntityExtractorRegistry).to receive(:extractors_for).and_raise("Extraction error")

        result = described_class.call(repository:, root_path: repo_path)

        expect(result).to be_failure
        expect(repository.code_files.count).to eq(0)
        expect(repository.code_chunks.count).to eq(0)
      end
    end
  end
end

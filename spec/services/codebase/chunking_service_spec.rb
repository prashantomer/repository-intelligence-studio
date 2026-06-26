require "rails_helper"

RSpec.describe Codebase::ChunkingService, type: :service do
  let(:repository) do
    Repository.create!(
      name: "test-repo",
      github_url: "https://github.com/test/repo",
      default_branch: "main",
      tracked_branch: "main"
    )
  end

  let(:repo_path) { Rails.root.join("spec/fixtures/chunking_repo") }

  before do
    FileUtils.mkdir_p(repo_path)
  end

  after do
    FileUtils.rm_rf(repo_path) if Dir.exist?(repo_path)
  end

  describe "#call" do
    it "generates chunks from code files" do
      ruby_code = "class MyClass\n" \
                  "  def method1\n" \
                  "    puts 'hello'\n" \
                  "  end\n" \
                  "\n" \
                  "  def method2\n" \
                  "    puts 'world'\n" \
                  "  end\n" \
                  "end\n"

      File.write(repo_path.join("test.rb"), ruby_code)
      code_file = repository.code_files.create!(
        path: "test.rb",
        language: "ruby",
        content_hash: Digest::SHA256.hexdigest(ruby_code)
      )

      result = described_class.call(repository:, root_path: repo_path)

      expect(result).to be_success
      expect(result.data.count).to be > 0
    end

    it "calculates token count accurately using character-based approximation" do
      test_text = "class MyClass\n  def method\n    puts 'hello'\n  end\nend"
      File.write(repo_path.join("test.rb"), test_text)

      code_file = repository.code_files.create!(
        path: "test.rb",
        language: "ruby",
        content_hash: Digest::SHA256.hexdigest(test_text)
      )

      repository.entities.create!(
        code_file:,
        entity_type: "class",
        name: "MyClass",
        signature: "class MyClass",
        metadata_json: { line_number: 1 }
      )

      result = described_class.call(repository:, root_path: repo_path)

      expect(result).to be_success
      chunks = repository.code_chunks.all
      chunks.each do |chunk|
        expected_count = (chunk.chunk_text.length / 4.0).ceil
        expect(chunk.token_count).to eq(expected_count)
      end
    end

    it "creates file-based chunks for files without entities" do
      large_code = "line 1\n" * 100

      File.write(repo_path.join("large.rb"), large_code)
      code_file = repository.code_files.create!(
        path: "large.rb",
        language: "ruby",
        content_hash: Digest::SHA256.hexdigest(large_code)
      )

      result = described_class.call(repository:, root_path: repo_path)

      expect(result).to be_success
      chunks = repository.code_chunks.where(code_file:)
      expect(chunks.count).to be > 1

      chunks.each do |chunk|
        expect(chunk.start_line).to be > 0
        expect(chunk.end_line).to be >= chunk.start_line
        expect(chunk.chunk_type).to eq("file")
      end
    end

    it "deletes existing chunks before creating new ones" do
      ruby_code = "class MyClass\nend"
      File.write(repo_path.join("test.rb"), ruby_code)
      code_file = repository.code_files.create!(
        path: "test.rb",
        language: "ruby",
        content_hash: Digest::SHA256.hexdigest(ruby_code)
      )

      # Create initial chunks
      described_class.call(repository:, root_path: repo_path)
      initial_chunk_count = repository.code_chunks.count

      # Run again
      described_class.call(repository:, root_path: repo_path)

      # Should have same count (old deleted, new created)
      expect(repository.code_chunks.count).to eq(initial_chunk_count)
    end

    it "skips files that don't exist on disk" do
      File.write(repo_path.join("exists.rb"), "puts 'hello'")
      code_file1 = repository.code_files.create!(
        path: "exists.rb",
        language: "ruby",
        content_hash: "abc123"
      )
      code_file2 = repository.code_files.create!(
        path: "missing.rb",
        language: "ruby",
        content_hash: "def456"
      )

      result = described_class.call(repository:, root_path: repo_path)

      expect(result).to be_success
      chunks = repository.code_chunks
      expect(chunks.where(code_file: code_file1).count).to be > 0
      expect(chunks.where(code_file: code_file2).count).to eq(0)
    end

    describe "token count accuracy" do
      [
        { text: "a", expected: 1 },
        { text: "hello", expected: 2 },
        { text: "hello world", expected: 3 },
        { text: "x" * 100, expected: 25 },
        { text: "x" * 101, expected: 26 }
      ].each do |test_case|
        it "calculates token count for text as #{test_case[:expected]}" do
          test_repo_path = repo_path
          test_repo = repository
          service = described_class.new(repository: test_repo, root_path: test_repo_path)
          count = service.send(:calculate_token_count, test_case[:text])
          expect(count).to eq(test_case[:expected])
        end
      end
    end
  end
end

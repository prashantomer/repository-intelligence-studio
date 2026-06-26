require "open3"

module Repositories
  class RemoteMetadataFetcher < ApplicationService
    def initialize(repository:)
      @repository = repository
    end

    def call
      stdout, stderr, status = Open3.capture3(
        "git", "ls-remote", "--symref", repository.github_url, "HEAD"
      )

      unless status.success?
        return ApplicationResult.failure(error: stderr.presence || "Unable to inspect remote repository")
      end

      ApplicationResult.success(
        data: {
          default_branch: extract_default_branch(stdout),
          head_sha: extract_head_sha(stdout)
        }
      )
    end

    private

    attr_reader :repository

    def extract_default_branch(output)
      output.lines.each do |line|
        next unless line.start_with?("ref:")

        ref = line.split[1]
        return ref.delete_prefix("refs/heads/")
      end

      repository.default_branch
    end

    def extract_head_sha(output)
      line = output.lines.find { |entry| entry.end_with?("HEAD\n") && !entry.start_with?("ref:") }
      line&.split&.first
    end
  end
end

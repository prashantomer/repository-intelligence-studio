require "fileutils"
require "open3"

module Repositories
  class CloneService < ApplicationService
    def initialize(repository:, branch_name:, target_path:)
      @repository = repository
      @branch_name = branch_name
      @target_path = target_path
    end

    def call
      FileUtils.rm_rf(target_path)
      FileUtils.mkdir_p(target_path.parent)

      stdout, stderr, status = Open3.capture3(
        "git", "clone", "--depth", "1", "--branch", branch_name, repository.github_url, target_path.to_s
      )

      unless status.success?
        return ApplicationResult.failure(error: stderr.presence || stdout.presence || "Clone failed")
      end

      ApplicationResult.success(data: { target_path: target_path.to_s })
    end

    private

    attr_reader :repository, :branch_name, :target_path
  end
end

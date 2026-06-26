module Repositories
  class CreateService < ApplicationService
    def initialize(attributes:, user:)
      @attributes = attributes.to_h.symbolize_keys
      @user = user
    end

    def call
      repository = Repository.new(
        user:,
        name: attributes[:name].presence || infer_name_from_url,
        github_url: normalized_github_url,
        default_branch: attributes[:default_branch].presence || attributes[:tracked_branch].presence || "main",
        tracked_branch: attributes[:tracked_branch].presence || attributes[:default_branch].presence || "main"
      )

      if repository.save
        ApplicationResult.success(data: repository)
      else
        ApplicationResult.failure(error: repository)
      end
    end

    private

    attr_reader :attributes, :user

    def normalized_github_url
      url = attributes[:github_url].to_s.strip
      url.end_with?(".git") ? url : "#{url}.git"
    end

    def infer_name_from_url
      normalized_github_url.split("/").last.to_s.delete_suffix(".git")
    end
  end
end

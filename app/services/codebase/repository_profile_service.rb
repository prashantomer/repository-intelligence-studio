require "yaml"

module Codebase
  class RepositoryProfileService < ApplicationService
    def initialize(repository:)
      @repository = repository
    end

    def call
      code_files = repository.code_files
      language_counts = code_files.group(:language).count
      paths = code_files.limit(10_000).pluck(:path)
      profile_key = infer_profile_key(language_counts:, paths:)
      profile_config = profiles.fetch(profile_key.to_s)

      ApplicationResult.success(
        data: {
          key: profile_key.to_s,
          label: profile_config.fetch("label"),
          dominant_languages: dominant_languages(language_counts),
          impact_focus: profile_config.fetch("impact_focus"),
          matched_markers: matched_markers(profile_config.fetch("markers"), paths)
        }
      )
    end

    private

    attr_reader :repository

    def infer_profile_key(language_counts:, paths:)
      return :rails if rails_repo?(language_counts:, paths:)
      return :python if python_repo?(language_counts:, paths:)
      return :node if node_repo?(language_counts:, paths:)
      return :java if java_repo?(language_counts:, paths:)
      return :python if dominant_languages(language_counts).include?("python")
      return :node if (dominant_languages(language_counts) & %w[javascript typescript]).any?
      return :java if (dominant_languages(language_counts) & %w[java kotlin scala]).any?
      return :rails if dominant_languages(language_counts).include?("ruby")

      :generic
    end

    def rails_repo?(language_counts:, paths:)
      language_counts.key?("ruby") &&
        includes_all_markers?(paths, [ "Gemfile", "config/routes.rb" ])
    end

    def python_repo?(language_counts:, paths:)
      language_counts.key?("python") &&
        includes_any_marker?(paths, [ "pyproject.toml", "requirements.txt", "setup.py", "manage.py" ])
    end

    def node_repo?(language_counts:, paths:)
      (language_counts.key?("javascript") || language_counts.key?("typescript")) &&
        includes_any_marker?(paths, [ "package.json", "tsconfig.json" ])
    end

    def java_repo?(language_counts:, paths:)
      (language_counts.key?("java") || language_counts.key?("kotlin") || language_counts.key?("scala")) &&
        includes_any_marker?(paths, [ "pom.xml", "build.gradle", "build.gradle.kts", "settings.gradle" ])
    end

    def dominant_languages(language_counts)
      language_counts.sort_by { |_language, count| -count }.first(3).map(&:first)
    end

    def includes_all_markers?(paths, markers)
      markers.all? { |marker| path_marker_present?(paths, marker) }
    end

    def includes_any_marker?(paths, markers)
      markers.any? { |marker| path_marker_present?(paths, marker) }
    end

    def matched_markers(markers, paths)
      markers.select { |marker| path_marker_present?(paths, marker) }
    end

    def path_marker_present?(paths, marker)
      paths.any? do |path|
        path == marker || path.start_with?("#{marker}/") || path.include?("/#{marker}/")
      end
    end

    def profiles
      self.class.profiles
    end

    def self.profiles
      @profiles ||= YAML.load_file(Rails.root.join("config", "repository_profiles.yml"))
                      .deep_stringify_keys
                      .fetch("profiles")
                      .freeze
    end
  end
end

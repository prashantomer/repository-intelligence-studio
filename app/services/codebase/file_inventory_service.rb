require "digest"
require "pathname"

module Codebase
  class FileInventoryService < ApplicationService
    IGNORED_DIRECTORIES = %w[
      .git
      node_modules
      vendor
      tmp
      log
      coverage
      storage
    ].freeze

    LANGUAGE_MAP = {
      ".rb" => "ruby",
      ".js" => "javascript",
      ".jsx" => "javascript",
      ".ts" => "typescript",
      ".tsx" => "typescript"
    }.freeze

    def initialize(repository:, root_path:)
      @repository = repository
      @root_path = Pathname.new(root_path)
    end

    def call
      files = []

      Dir.glob(root_path.join("**", "*"), File::FNM_DOTMATCH).sort.each do |absolute_path|
        path = Pathname.new(absolute_path)
        next unless path.file?
        next if ignored_path?(path)

        language = detect_language(path)
        next if language.blank?

        relative_path = path.relative_path_from(root_path).to_s
        content = path.binread

        files << repository.code_files.create!(
          path: relative_path,
          language: language,
          content_hash: Digest::SHA256.hexdigest(content),
          size_bytes: content.bytesize
        )
      end

      ApplicationResult.success(data: files)
    end

    private

    attr_reader :repository, :root_path

    def ignored_path?(path)
      relative_segments = path.relative_path_from(root_path).each_filename.to_a
      relative_segments.any? { |segment| IGNORED_DIRECTORIES.include?(segment) }
    end

    def detect_language(path)
      LANGUAGE_MAP[path.extname]
    end
  end
end

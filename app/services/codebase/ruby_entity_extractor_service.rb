module Codebase
  class RubyEntityExtractorService < ApplicationService
    ENTITY_PATTERN = /^\s*(class|module)\s+([A-Z][A-Za-z0-9_:]*)/.freeze

    def initialize(code_file:, absolute_path:)
      @code_file = code_file
      @absolute_path = absolute_path
    end

    def call
      return ApplicationResult.success(data: []) unless code_file.language == "ruby"

      entities = []

      File.foreach(absolute_path).with_index(1) do |line, line_number|
        match = line.match(ENTITY_PATTERN)
        next unless match

        name = match[2].split("::").last
        namespace = match[2].include?("::") ? match[2].split("::")[0...-1].join("::") : nil

        entities << code_file.repository.entities.create!(
          code_file:,
          entity_type: infer_entity_type(code_file.path),
          name:,
          namespace:,
          signature: line.strip,
          metadata_json: { line_number: line_number, declaration: match[1] }
        )
      end

      ApplicationResult.success(data: entities)
    end

    private

    attr_reader :code_file, :absolute_path

    def infer_entity_type(path)
      return "controller" if path.include?("/controllers/") || path.end_with?("_controller.rb")
      return "model" if path.include?("/models/")
      return "job" if path.include?("/jobs/") || path.end_with?("_job.rb")
      return "service" if path.include?("/services/")

      "module"
    end
  end
end

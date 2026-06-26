module Codebase
  class JsTsEntityExtractorService < ApplicationService
    PATTERNS = [
      [/^\s*export\s+class\s+([A-Z][A-Za-z0-9_]*)/, "class"],
      [/^\s*class\s+([A-Z][A-Za-z0-9_]*)/, "class"],
      [/^\s*export\s+function\s+([a-zA-Z_$][A-Za-z0-9_$]*)/, "function"],
      [/^\s*function\s+([a-zA-Z_$][A-Za-z0-9_$]*)/, "function"],
      [/^\s*export\s+const\s+([a-zA-Z_$][A-Za-z0-9_$]*)\s*=\s*\(/, "function"],
      [/^\s*export\s+const\s+([A-Z][A-Za-z0-9_$]*)\s*=/, "module"]
    ].freeze

    def initialize(code_file:, absolute_path:)
      @code_file = code_file
      @absolute_path = absolute_path
    end

    def call
      entities = []

      File.foreach(absolute_path).with_index(1) do |line, line_number|
        pattern, declaration = PATTERNS.find { |regex, _type| line.match?(regex) }
        next unless pattern

        match = line.match(pattern)
        next unless match

        entities << code_file.repository.entities.create!(
          code_file:,
          entity_type: infer_entity_type,
          name: match[1],
          signature: line.strip,
          metadata_json: { line_number:, declaration:, language: code_file.language }
        )
      end

      ApplicationResult.success(data: entities)
    end

    private

    attr_reader :code_file, :absolute_path

    def infer_entity_type
      path = code_file.path
      return "controller" if path.include?("controllers")
      return "service" if path.include?("services")

      "module"
    end
  end
end

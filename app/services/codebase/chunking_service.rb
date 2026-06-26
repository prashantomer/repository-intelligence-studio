module Codebase
  class ChunkingService < ApplicationService
    MAX_FILE_LINES = 80

    def initialize(repository:, root_path:)
      @repository = repository
      @root_path = root_path
    end

    def call
      chunks = []

      repository.code_files.includes(:entities).find_each do |code_file|
        # Delete existing chunks for this file before recreating
        repository.code_chunks.where(code_file_id: code_file.id).delete_all

        absolute_path = File.join(root_path, code_file.path)
        next unless File.exist?(absolute_path)

        file_lines = File.readlines(absolute_path, chomp: false)
        entity_chunks = build_entity_chunks(code_file, file_lines)
        chunks.concat(entity_chunks)

        if entity_chunks.empty?
          chunks.concat(build_file_chunks(code_file, file_lines))
        end
      end

      ApplicationResult.success(data: chunks)
    end

    private

    attr_reader :repository, :root_path

    def build_entity_chunks(code_file, file_lines)
      sorted_entities = code_file.entities.order(Arel.sql("COALESCE((metadata_json->>'line_number')::int, 0) ASC"))
      return [] if sorted_entities.empty?

      chunks = []

      sorted_entities.each_with_index do |entity, index|
        start_line = entity.metadata_json["line_number"].to_i
        next if start_line <= 0

        next_entity = sorted_entities[index + 1]
        end_line = if next_entity&.metadata_json&.[]("line_number").to_i.to_i > 0
          next_entity.metadata_json["line_number"].to_i - 1
        else
          file_lines.length
        end

        chunk_text = slice_lines(file_lines, start_line, end_line)
        next if chunk_text.blank?

        chunks << repository.code_chunks.create!(
          code_file: code_file,
          entity: entity,
          chunk_type: entity.entity_type,
          chunk_text: chunk_text,
          start_line: start_line,
          end_line: end_line,
          token_count: calculate_token_count(chunk_text)
        )
      end

      chunks
    end

    def build_file_chunks(code_file, file_lines)
      chunks = []
      file_lines.each_slice(MAX_FILE_LINES).with_index do |slice, index|
        start_line = (index * MAX_FILE_LINES) + 1
        end_line = start_line + slice.length - 1
        chunk_text = slice.join

        chunks << repository.code_chunks.create!(
          code_file: code_file,
          chunk_type: "file",
          chunk_text: chunk_text,
          start_line: start_line,
          end_line: end_line,
          token_count: calculate_token_count(chunk_text)
        )
      end

      chunks
    end

    def slice_lines(file_lines, start_line, end_line)
      file_lines[(start_line - 1)..(end_line - 1)]&.join.to_s
    end

    def calculate_token_count(text)
      # Improved token counting: use character-based approximation (avg 4 chars per token)
      # This is more accurate than simple whitespace split for code
      (text.length / 4.0).ceil
    end
  end
end

module Assistant
  class LocalAnswerService < ApplicationService
    def initialize(repository:, question:, chunks:)
      @repository = repository
      @question = question
      @chunks = chunks
    end

    def call
      ApplicationResult.success(
        data: {
          answer: build_answer,
          citations: build_citations,
          prompt_tokens: approximate_tokens(question),
          completion_tokens: approximate_tokens(build_answer)
        }
      )
    end

    private

    attr_reader :repository, :question, :chunks

    def build_answer
      return "No relevant indexed context was found for this repository yet." if chunks.empty?

      lines = []
      lines << "Repository: #{repository.name}"
      lines << "Question: #{question}"
      lines << ""
      lines << "Most relevant indexed context:"

      chunks.first(3).each_with_index do |chunk, index|
        lines << "#{index + 1}. #{chunk.code_file.path}:#{chunk.start_line}-#{chunk.end_line} (#{chunk.chunk_type})"
      end

      entity_names = chunks.filter_map { |chunk| chunk.entity&.name }.uniq.first(8)
      unless entity_names.empty?
        lines << ""
        lines << "Related entities: #{entity_names.join(', ')}"
      end

      lines << ""
      lines << "Summary:"
      lines << synthesize_summary
      lines.join("\n")
    end

    def synthesize_summary
      top = chunks.first
      snippet = top.chunk_text.gsub(/\s+/, " ").strip
      "The strongest repository-scoped evidence is in #{top.code_file.path}. " \
        "The retrieved chunks suggest this question relates to #{chunks.map(&:chunk_type).uniq.join(', ')} logic. " \
        "Top snippet: #{snippet.truncate(220)}"
    end

    def build_citations
      chunks.first(5).map do |chunk|
        {
          path: chunk.code_file.path,
          start_line: chunk.start_line,
          end_line: chunk.end_line,
          chunk_type: chunk.chunk_type,
          entity_name: chunk.entity&.name
        }
      end
    end

    def approximate_tokens(text)
      (text.to_s.length / 4.0).ceil
    end
  end
end

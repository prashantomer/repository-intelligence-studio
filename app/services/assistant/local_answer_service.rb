module Assistant
  class LocalAnswerService < ApplicationService
    def initialize(repository:, question:, chunks:, conversation_context: nil, context_override: nil, citations_override: nil)
      @repository = repository
      @question = question
      @chunks = chunks
      @conversation_context = conversation_context || {}
      @context_override = context_override
      @citations_override = citations_override
    end

    def call
      answer = build_answer

      ApplicationResult.success(
        data: {
          answer:,
          citations: build_citations,
          prompt_tokens: approximate_tokens(question),
          completion_tokens: approximate_tokens(answer)
        }
      )
    end

    private

    attr_reader :repository, :question, :chunks, :conversation_context, :context_override, :citations_override

    def build_answer
      return build_context_override_answer if context_override.present?
      return "No relevant indexed context was found for this repository yet." if chunks.empty?

      lines = []
      lines << "Repository: #{repository.name}"
      lines << "Question: #{question}"

      if conversation_context[:prompt_transcript].present? && conversation_context[:prompt_transcript] != "No prior conversation context."
        lines << "Recent conversation context:"
        lines << conversation_context[:prompt_transcript]
        lines << ""
      end

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
      return citations_override if citations_override.present?

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

    def build_context_override_answer
      lines = []
      lines << "Repository: #{repository.name}"
      lines << "Question: #{question}"
      lines << ""
      lines << "Structured repository evidence:"
      lines << context_override
      lines.join("\n")
    end
  end
end

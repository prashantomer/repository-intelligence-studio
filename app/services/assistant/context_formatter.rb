module Assistant
  class ContextFormatter
    def self.call(chunks:)
      return "No indexed repository context found." if chunks.empty?

      chunks.first(6).map do |chunk|
        <<~BLOCK
          File: #{chunk.code_file.path}
          Lines: #{chunk.start_line}-#{chunk.end_line}
          Type: #{chunk.chunk_type}
          Content:
          #{chunk.chunk_text.to_s.strip}
        BLOCK
      end.join("\n\n")
    end
  end
end

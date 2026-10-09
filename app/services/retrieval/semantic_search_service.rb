module Retrieval
  class SemanticSearchService < ApplicationService
    DEFAULT_LIMIT = 8

    def initialize(repository:, query:, limit: DEFAULT_LIMIT)
      @repository = repository
      @query = query
      @limit = limit
    end

    def call
      mismatch_error = embedding_mismatch_error
      return ApplicationResult.failure(error: mismatch_error) if mismatch_error.present?

      semantic_result = semantic_search_chunks
      keyword_chunks = keyword_search_chunks
      semantic_chunks = validated_semantic_chunks(semantic_result[:chunks], keyword_chunks)

      chunks = merge_chunks(semantic_chunks, keyword_chunks)

      if chunks.empty? && semantic_result[:error].present?
        return ApplicationResult.failure(error: semantic_result[:error])
      end

      ApplicationResult.success(data: chunks.first(limit))
    rescue ActiveRecord::StatementInvalid => error
      return ApplicationResult.failure(error: resync_error_message) if vector_dimension_error?(error)

      raise
    end

    private

    attr_reader :repository, :query, :limit

    def embedding_mismatch_error
      return nil unless repository.code_chunks.with_embedding.exists?
      return nil if repository.embedding_settings_aligned?

      resync_error_message
    end

    def vector_dimension_error?(error)
      error.message.include?("different vector dimensions")
    end

    def resync_error_message
      "Stored repository embeddings were generated with a different embedding configuration. Re-sync this repository to rebuild vectors for #{repository.embedding_provider} / #{repository.embedding_model}."
    end

    def semantic_search_chunks
      return { chunks: [], error: nil } unless repository.code_chunks.with_embedding.exists?

      embedding_result = Embeddings::TextEmbeddingService.call(text: query, repository:)
      return { chunks: [], error: embedding_result.error.to_s } if embedding_result.failure?

      query_embedding = embedding_result.data
      query_literal = Embeddings::VectorLiteral.dump(query_embedding)

      chunks = repository.code_chunks.with_embedding
                         .includes(:code_file, :entity)
                         .order(
                           Arel.sql(
                             ActiveRecord::Base.send(
                               :sanitize_sql_array,
                               ["embedding <=> ?::vector", query_literal]
                             )
                           )
                         )
                         .limit(limit)
                         .to_a

      { chunks:, error: nil }
    end

    def keyword_search_chunks
      tokens = query_tokens
      return [] if tokens.empty?

      conditions = tokens.flat_map do |token|
        escaped = "%#{ActiveRecord::Base.sanitize_sql_like(token)}%"
        [
          CodeChunk.sanitize_sql_array(["code_chunks.chunk_text ILIKE ?", escaped]),
          CodeChunk.sanitize_sql_array(["code_files.path ILIKE ?", escaped]),
          CodeChunk.sanitize_sql_array(["code_files.language ILIKE ?", escaped]),
          CodeChunk.sanitize_sql_array(["entities.name ILIKE ?", escaped]),
          CodeChunk.sanitize_sql_array(["entities.entity_type ILIKE ?", escaped])
        ]
      end

      repository.code_chunks
                .joins(:code_file)
                .left_joins(:entity)
                .includes(:code_file, :entity)
                .where(conditions.join(" OR "))
                .limit(limit * 12)
                .to_a
                .uniq { |chunk| chunk.id }
                .sort_by { |chunk| -keyword_score(chunk) }
                .first(limit)
    end

    def merge_chunks(semantic_chunks, keyword_chunks)
      return keyword_chunks if structured_query? && keyword_chunks.any?

      combined = []
      seen_ids = {}

      if prioritize_keyword_chunks?
        append_unique_chunks(combined, seen_ids, keyword_chunks)
        append_unique_chunks(combined, seen_ids, semantic_chunks)
      else
        append_unique_chunks(combined, seen_ids, semantic_chunks)
        append_unique_chunks(combined, seen_ids, keyword_chunks)
      end

      combined
    end

    def append_unique_chunks(target, seen_ids, chunks)
      chunks.each do |chunk|
        next if seen_ids[chunk.id]

        seen_ids[chunk.id] = true
        target << chunk
      end
    end

    def prioritize_keyword_chunks?
      structured_query? || query_tokens.one? || query.length <= 24
    end

    def query_tokens
      @query_tokens ||= begin
        normalized_query = normalized_query_string
        raw_tokens = query.to_s.downcase.scan(/[a-z0-9_:-]+/).uniq
        raw_tokens.unshift(normalized_query) if normalized_query.present?

        expanded = raw_tokens.flat_map do |token|
          variants = [token]
          variants << token.singularize if token.respond_to?(:singularize)
          variants << token.pluralize if token.respond_to?(:pluralize)
          variants
        end

        expanded.reject(&:blank?).uniq.first(6)
      end
    end

    def validated_semantic_chunks(chunks, keyword_chunks)
      return [] if structured_query? && keyword_chunks.any?

      return chunks unless structured_query?

      chunks.select { |chunk| strong_keyword_match?(chunk) }
    end

    def structured_query?
      @structured_query ||= begin
        source = query.to_s.strip
        return false if source.blank?

        source.match?(/[A-Z]/) ||
          source.include?("_") ||
          source.include?("!") ||
          source.include?("?") ||
          source.include?("::") ||
          source.include?("/") ||
          source.match?(/\.[a-z0-9]+\z/i)
      end
    end

    def keyword_score(chunk)
      path = chunk.code_file.path.to_s.downcase
      language = chunk.code_file.language.to_s.downcase
      entity_name = chunk.entity&.name.to_s.downcase
      entity_type = chunk.entity&.entity_type.to_s.downcase
      chunk_text = chunk.chunk_text.to_s.downcase
      normalized_query = normalized_query_string

      base_score = query_tokens.sum do |token|
        score = 0
        score += 120 if exact_query_match?(path, normalized_query)
        score += 110 if exact_query_match?(entity_name, normalized_query)
        score += 90 if exact_query_match?(chunk_text, normalized_query)
        score += 72 if line_contains_query?(chunk_text, normalized_query)
        score += 36 if whole_token_match?(path, token)
        score += 28 if whole_token_match?(entity_name, token)
        score += 20 if whole_token_match?(chunk_text, token)
        score += 12 if path.include?(token)
        score += 8 if entity_name.include?(token)
        score += 6 if entity_type.include?(token)
        score += 4 if language.include?(token)
        score += 2 if chunk_text.include?(token)
        score
      end

      base_score + definition_match_score(chunk.chunk_text.to_s)
    end

    def strong_keyword_match?(chunk)
      normalized_query = normalized_query_string
      path = chunk.code_file.path.to_s.downcase
      entity_name = chunk.entity&.name.to_s.downcase
      chunk_text = chunk.chunk_text.to_s.downcase

      exact_query_match?(path, normalized_query) ||
        exact_query_match?(entity_name, normalized_query) ||
        exact_query_match?(chunk_text, normalized_query) ||
        line_contains_query?(chunk_text, normalized_query) ||
        query_tokens.any? do |token|
          whole_token_match?(path, token) ||
            whole_token_match?(entity_name, token) ||
            whole_token_match?(chunk_text, token)
        end
    end

    def normalized_query_string
      @normalized_query_string ||= query.to_s.downcase.strip.sub(/\A`(.+)`\z/, "\\1")
    end

    def exact_query_match?(text, query_string)
      return false if query_string.blank? || text.blank?

      text.include?(query_string)
    end

    def whole_token_match?(text, token)
      return false if token.blank? || text.blank?

      text.match?(/(?<![a-z0-9_])#{Regexp.escape(token)}(?![a-z0-9_])/i)
    end

    def line_contains_query?(text, query_string)
      return false if query_string.blank? || text.blank?

      text.lines.any? { |line| line.downcase.include?(query_string) }
    end

    def definition_match_score(chunk_text)
      return 0 unless structured_query?

      normalized = normalized_query_string
      patterns = []

      patterns << /^\s*def\s+(?:self\.)?#{Regexp.escape(normalized)}\b/i
      patterns << /^\s*def\s+(?:self\.)?#{Regexp.escape(normalized.sub(/[!?]\z/, ""))}[!?]?\b/i if normalized.match?(/[!?]\z/)
      patterns << /^\s*class\s+#{Regexp.escape(normalized)}\b/i
      patterns << /^\s*module\s+#{Regexp.escape(normalized)}\b/i

      lines = chunk_text.lines.first(40)
      return 260 if lines.any? { |line| patterns.any? { |pattern| line.match?(pattern) } }

      0
    end
  end
end

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

      embedding_result = Embeddings::TextEmbeddingService.call(text: query, repository:)
      return embedding_result if embedding_result.failure?

      query_embedding = embedding_result.data
      query_literal = Embeddings::VectorLiteral.dump(query_embedding)

      chunks = repository.code_chunks.with_embedding
                         .order(
                           Arel.sql(
                             ActiveRecord::Base.send(
                               :sanitize_sql_array,
                               ["embedding <=> ?::vector", query_literal]
                             )
                           )
                         )
                         .limit(limit)

      ApplicationResult.success(data: chunks)
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
  end
end

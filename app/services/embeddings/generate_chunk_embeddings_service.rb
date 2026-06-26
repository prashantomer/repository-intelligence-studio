module Embeddings
  class GenerateChunkEmbeddingsService < ApplicationService
    def initialize(repository:)
      @repository = repository
    end

    def call
      updated_chunks = []

      repository.code_chunks.find_each do |chunk|
        embedding_result = TextEmbeddingService.call(text: chunk.chunk_text, repository:)
        return embedding_result if embedding_result.failure?

        embedding = embedding_result.data
        CodeChunk.where(id: chunk.id).update_all(
          ["embedding = ?::vector", Embeddings::VectorLiteral.dump(embedding)]
        )
        updated_chunks << chunk
      end

      repository.update!(
        indexed_embedding_provider: repository.embedding_provider,
        indexed_embedding_model: repository.embedding_model
      )

      ApplicationResult.success(data: updated_chunks)
    end

    private

    attr_reader :repository
  end
end

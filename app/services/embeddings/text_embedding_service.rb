module Embeddings
  class TextEmbeddingService < ApplicationService
    VECTOR_SIZE = 1024

    def initialize(text:, repository: nil)
      @text = text
      @repository = repository
    end

    def call
      return remote_embedding if repository&.embedding_provider.present? && !repository.embedding_provider_local?

      ApplicationResult.success(data: deterministic_embedding(text))
    end

    private

    attr_reader :text, :repository

    def deterministic_embedding(input)
      values = Array.new(VECTOR_SIZE, 0.0)

      input.each_byte.with_index do |byte, index|
        slot = index % VECTOR_SIZE
        values[slot] += byte / 255.0
      end

      normalize(values)
    end

    def normalize(values)
      magnitude = Math.sqrt(values.sum { |value| value * value })
      return values if magnitude.zero?

      values.map { |value| value / magnitude }
    end

    def remote_embedding
      client = Ai::ProviderFactory.for_embeddings(repository)
      return ApplicationResult.failure(error: "Unsupported embedding provider") if client.blank?

      result = client.embedding(model: repository.embedding_model, text:)
      return contextual_failure(result.error) if result.failure?

      embedding = normalize_remote_embedding(result.data)
      return contextual_failure("Embedding response was empty") if embedding.blank?

      ApplicationResult.success(data: embedding)
    end

    def normalize_remote_embedding(payload)
      case repository.embedding_provider
      when Repository::EMBEDDING_PROVIDERS[:openai]
        payload.fetch("data", []).first&.fetch("embedding", nil)
      when Repository::EMBEDDING_PROVIDERS[:ollama]
        payload["embeddings"]&.first || payload["embedding"]
      end
    end

    def contextual_failure(error_message)
      ApplicationResult.failure(
        error: "Embedding provider #{repository.embedding_provider} failed for model #{repository.embedding_model}: #{error_message}"
      )
    end
  end
end

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

      started_at = current_time_ms
      result = client.embedding(model: repository.embedding_model, text:)
      latency_ms = current_time_ms - started_at

      if result.failure?
        record_provider_call(status: :failed, latency_ms:, error_message: result.error)
        return contextual_failure(result.error)
      end

      embedding = normalize_remote_embedding(result.data)
      if embedding.blank?
        record_provider_call(status: :failed, latency_ms:, response_payload: result.data, error_message: "Embedding response was empty")
        return contextual_failure("Embedding response was empty")
      end

      prompt_tokens, completion_tokens = extract_usage(result.data)
      record_provider_call(
        status: :success,
        latency_ms:,
        prompt_tokens:,
        completion_tokens:,
        response_payload: result.data,
        embedding:
      )

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

    def extract_usage(payload)
      case repository.embedding_provider
      when Repository::EMBEDDING_PROVIDERS[:openai]
        usage = payload.fetch("usage", {})
        [usage["prompt_tokens"].to_i, 0]
      else
        [0, 0]
      end
    end

    def record_provider_call(status:, latency_ms:, prompt_tokens: 0, completion_tokens: 0, response_payload: {}, embedding: nil, error_message: nil)
      Ai::ProviderCallLogRecorder.call(
        repository:,
        user: repository.user,
        provider: repository.embedding_provider,
        operation_type: :embedding,
        model: repository.embedding_model,
        endpoint: embedding_endpoint,
        request_metadata: {
          input_chars: text.to_s.length,
          input_preview: text.to_s.squish.truncate(220)
        },
        response_metadata: {
          response_keys: response_payload.respond_to?(:keys) ? response_payload.keys : [],
          dimensions: embedding&.size
        },
        prompt_tokens:,
        completion_tokens:,
        latency_ms:,
        status:,
        error_message:
      )
    end

    def embedding_endpoint
      case repository.embedding_provider
      when Repository::EMBEDDING_PROVIDERS[:openai]
        "/v1/embeddings"
      when Repository::EMBEDDING_PROVIDERS[:ollama]
        "/api/embed"
      else
        "local"
      end
    end

    def current_time_ms
      Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)
    end
  end
end

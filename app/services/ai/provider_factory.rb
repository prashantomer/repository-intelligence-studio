module Ai
  class ProviderFactory
    def self.for_assistant(repository)
      case repository.assistant_provider
      when Repository::ASSISTANT_PROVIDERS[:openai]
        Providers::OpenaiClient.new
      when Repository::ASSISTANT_PROVIDERS[:anthropic]
        Providers::AnthropicClient.new
      when Repository::ASSISTANT_PROVIDERS[:ollama]
        Providers::OllamaClient.new(base_url: repository.ollama_base_url)
      end
    end

    def self.for_embeddings(repository)
      case repository.embedding_provider
      when Repository::EMBEDDING_PROVIDERS[:openai]
        Providers::OpenaiClient.new
      when Repository::EMBEDDING_PROVIDERS[:ollama]
        Providers::OllamaClient.new(base_url: repository.ollama_base_url)
      end
    end
  end
end

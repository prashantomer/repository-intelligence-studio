module AiModelCatalog
  ASSISTANT_MODELS = {
    "local" => [
      "grounded-local"
    ],
    "openai" => [
      "gpt-4.1-mini",
      "gpt-4.1",
      "gpt-4o-mini"
    ],
    "anthropic" => [
      "claude-3-5-haiku-latest",
      "claude-3-5-sonnet-latest",
      "claude-3-7-sonnet-latest"
    ],
    "ollama" => [
      "llama3.1",
      "qwen2.5-coder",
      "mistral"
    ]
  }.freeze

  EMBEDDING_MODELS = {
    "local" => [
      "deterministic-v1"
    ],
    "openai" => [
      "text-embedding-3-small",
      "text-embedding-3-large"
    ],
    "ollama" => [
      "mxbai-embed-large:latest",
      "nomic-embed-text",
      "all-minilm"
    ]
  }.freeze

  def self.assistant_models_for(provider)
    ASSISTANT_MODELS.fetch(provider.to_s, ASSISTANT_MODELS.fetch("local"))
  end

  def self.embedding_models_for(provider)
    EMBEDDING_MODELS.fetch(provider.to_s, EMBEDDING_MODELS.fetch("local"))
  end

  def self.default_assistant_model_for(provider)
    assistant_models_for(provider).first
  end

  def self.default_embedding_model_for(provider)
    embedding_models_for(provider).first
  end
end

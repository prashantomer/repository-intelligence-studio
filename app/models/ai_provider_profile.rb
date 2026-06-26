module AiProviderProfile
  PROFILE = {
    "local" => {
      assistant_supported: true,
      embeddings_supported: true,
      credential_env: nil,
      connection_type: "built-in"
    },
    "openai" => {
      assistant_supported: true,
      embeddings_supported: false,
      credential_env: "OPENAI_API_KEY",
      connection_type: "api_key"
    },
    "anthropic" => {
      assistant_supported: true,
      embeddings_supported: false,
      credential_env: "ANTHROPIC_API_KEY",
      connection_type: "api_key"
    },
    "ollama" => {
      assistant_supported: true,
      embeddings_supported: true,
      credential_env: nil,
      connection_type: "base_url"
    }
  }.freeze

  def self.profile_for(provider)
    PROFILE.fetch(provider.to_s, PROFILE.fetch("local"))
  end

  def self.credential_configured?(provider)
    env_name = profile_for(provider)[:credential_env]
    return true if env_name.blank?

    ENV[env_name].present?
  end

  def self.assistant_ready?(provider)
    profile = profile_for(provider)
    return false unless profile[:assistant_supported]

    credential_configured?(provider)
  end

  def self.embedding_ready?(provider, ollama_base_url: nil)
    profile = profile_for(provider)
    return false unless profile[:embeddings_supported]
    return ollama_base_url.present? if provider.to_s == "ollama"

    credential_configured?(provider)
  end

  def self.requirement_label(provider)
    profile = profile_for(provider)
    return "Current embedding storage supports 1024-dimension local or Ollama models only" if provider.to_s == "openai"
    return "No external credential required" if profile[:credential_env].blank? && profile[:connection_type] == "built-in"
    return "Requires #{profile[:credential_env]}" if profile[:credential_env].present?
    return "Requires reachable Ollama base URL" if profile[:connection_type] == "base_url"

    "Runtime requirement unknown"
  end
end

class User < ApplicationRecord
  ASSISTANT_PROVIDERS = {
    local: "local",
    openai: "openai",
    anthropic: "anthropic",
    ollama: "ollama"
  }.freeze

  EMBEDDING_PROVIDERS = {
    local: "local",
    openai: "openai",
    ollama: "ollama"
  }.freeze

  has_many :repositories, dependent: :nullify
  has_many :conversations, dependent: :nullify
  has_many :provider_call_logs, dependent: :destroy

  attribute :assistant_provider, :string
  attribute :assistant_model, :string
  attribute :embedding_provider, :string
  attribute :embedding_model, :string
  attribute :ollama_base_url, :string

  enum :assistant_provider,
       ASSISTANT_PROVIDERS,
       prefix: :assistant_provider,
       validate: true

  enum :embedding_provider,
       EMBEDDING_PROVIDERS,
       prefix: :embedding_provider,
       validate: true

  before_validation :default_ai_settings

  validates :name, presence: true
  validates :assistant_model, presence: true
  validates :embedding_model, presence: true
  validates :ollama_base_url, presence: true, if: :ollama_selected?
  validate :embedding_provider_supported_by_current_storage

  def remote_assistant_provider?
    !assistant_provider_local?
  end

  def assistant_provider_ready?
    AiProviderProfile.assistant_ready?(assistant_provider)
  end

  def embedding_provider_ready?
    AiProviderProfile.embedding_ready?(embedding_provider, ollama_base_url:)
  end

  def assistant_provider_requirement
    AiProviderProfile.requirement_label(assistant_provider)
  end

  def embedding_provider_requirement
    AiProviderProfile.requirement_label(embedding_provider)
  end

  def ollama_selected?
    assistant_provider_ollama? || embedding_provider_ollama?
  end

  private

  def default_ai_settings
    self.assistant_provider ||= ASSISTANT_PROVIDERS[:local]
    self.assistant_model = AiModelCatalog.default_assistant_model_for(assistant_provider) if assistant_model.blank?
    self.embedding_provider ||= EMBEDDING_PROVIDERS[:local]
    self.embedding_model = AiModelCatalog.default_embedding_model_for(embedding_provider) if embedding_model.blank?
    self.ollama_base_url = "http://127.0.0.1:11434" if ollama_base_url.blank?
  end

  def embedding_provider_supported_by_current_storage
    return unless embedding_provider_openai?

    errors.add(
      :embedding_provider,
      "is not supported by the current 1024-dimension embedding storage. Use Local or Ollama for now."
    )
  end
end

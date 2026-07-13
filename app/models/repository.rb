class Repository < ApplicationRecord
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

  belongs_to :user
  has_many :repository_ingestions, dependent: :destroy
  has_many :audit_logs, dependent: :destroy
  has_many :code_files, dependent: :destroy
  has_many :code_chunks, dependent: :destroy
  has_many :entities, dependent: :destroy
  has_many :entity_relationships, dependent: :destroy
  has_many :repository_routes, dependent: :destroy
  has_many :conversations, dependent: :destroy
  has_many :provider_call_logs, dependent: :destroy
  has_many :dependency_edges, dependent: :destroy
  has_many :impact_reports, dependent: :destroy

  attribute :indexed_embedding_provider, :string
  attribute :indexed_embedding_model, :string

  enum :status,
       {
         pending: "pending",
         cloning: "cloning",
         parsing: "parsing",
         chunking: "chunking",
         embedding: "embedding",
         completed: "completed",
         failed: "failed",
         skipped: "skipped"
       },
       validate: true

  enum :visibility,
       {
         public_repo: "public"
       },
       prefix: :visibility,
       validate: true

  enum :provider,
       {
         github: "github"
       },
       validate: true

  before_validation :default_tracked_branch

  validates :name, presence: true
  validates :user, presence: true
  validates :github_url, presence: true, uniqueness: true
  validates :github_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }
  validates :default_branch, presence: true
  validates :tracked_branch, presence: true

  scope :recent_first, -> { order(created_at: :desc) }

  def latest_ingestion
    repository_ingestions.order(created_at: :desc).first
  end

  def active_ingestion
    repository_ingestions.where(status: RepositoryIngestion::ACTIVE_STATUSES).order(created_at: :desc).first
  end

  def supported_embedding_providers
    EMBEDDING_PROVIDERS.values
  end

  def assistant_provider
    user&.assistant_provider || self[:assistant_provider].presence || ASSISTANT_PROVIDERS[:local]
  end

  def assistant_model
    user&.assistant_model || self[:assistant_model].presence || "grounded-local"
  end

  def embedding_provider
    user&.embedding_provider || self[:embedding_provider].presence || EMBEDDING_PROVIDERS[:local]
  end

  def embedding_model
    user&.embedding_model || self[:embedding_model].presence || "deterministic-v1"
  end

  def ollama_base_url
    user&.ollama_base_url || self[:ollama_base_url].presence || "http://127.0.0.1:11434"
  end

  def embedding_settings_aligned?
    return true if indexed_embedding_provider.blank? && indexed_embedding_model.blank?

    indexed_embedding_provider == embedding_provider && indexed_embedding_model == embedding_model
  end

  def remote_assistant_provider?
    assistant_provider != ASSISTANT_PROVIDERS[:local]
  end

  def assistant_provider_local?
    assistant_provider == ASSISTANT_PROVIDERS[:local]
  end

  def assistant_provider_ollama?
    assistant_provider == ASSISTANT_PROVIDERS[:ollama]
  end

  def embedding_provider_local?
    embedding_provider == EMBEDDING_PROVIDERS[:local]
  end

  def embedding_provider_ollama?
    embedding_provider == EMBEDDING_PROVIDERS[:ollama]
  end

  def ollama_selected?
    assistant_provider_ollama? || embedding_provider_ollama?
  end

  private

  def default_tracked_branch
    self.tracked_branch = default_branch if tracked_branch.blank? && default_branch.present?
  end
end

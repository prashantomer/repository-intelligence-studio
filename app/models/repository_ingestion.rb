class RepositoryIngestion < ApplicationRecord
  ACTIVE_STATUSES = %w[pending cloning parsing chunking embedding].freeze
  STALE_AFTER = 1.minutes

  belongs_to :repository
  has_many :audit_logs, as: :auditable, dependent: :nullify

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

  validates :branch_name, presence: true
  validates :status, presence: true
  attribute :force_rebuild, :boolean, default: false

  scope :recent_first, -> { order(created_at: :desc) }

  def active?
    status.in?(ACTIVE_STATUSES)
  end

  def processable?
    pending?
  end

  def stale?
    return false unless active?

    reference_time = started_at || created_at
    reference_time <= STALE_AFTER.ago
  end
end

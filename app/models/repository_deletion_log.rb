class RepositoryDeletionLog < ApplicationRecord
  belongs_to :user, optional: true

  validates :deleted_repository_id, presence: true, uniqueness: true
  validates :name, presence: true
  validates :github_url, presence: true
  validates :deleted_at, presence: true
  validates :deletion_reason, presence: true

  scope :recent_first, -> { order(deleted_at: :desc, created_at: :desc) }

  def summary
    summary_json || {}
  end

  def workspace_cleanup_success?
    summary.fetch("workspace_cleanup_success", false)
  end
end

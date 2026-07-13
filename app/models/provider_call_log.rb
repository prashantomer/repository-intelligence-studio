class ProviderCallLog < ApplicationRecord
  belongs_to :repository
  belongs_to :user

  enum :operation_type,
       {
         assistant: "assistant",
         embedding: "embedding",
         impact_analysis: "impact_analysis"
       },
       validate: true

  enum :status,
       {
         success: "success",
         failed: "failed"
       },
       validate: true

  validates :provider, presence: true
  validates :model, presence: true

  scope :recent_first, -> { order(created_at: :desc) }
end

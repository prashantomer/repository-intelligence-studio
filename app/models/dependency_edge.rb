class DependencyEdge < ApplicationRecord
  belongs_to :repository

  validates :source_type, :source_id, :target_type, :target_id, :edge_type, presence: true
  validates :confidence, numericality: { greater_than: 0, less_than_or_equal_to: 1 }

  scope :recent_first, -> { order(created_at: :desc) }
end

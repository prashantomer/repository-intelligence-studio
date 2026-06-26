class CodeChunk < ApplicationRecord
  belongs_to :repository
  belongs_to :code_file
  belongs_to :entity, optional: true

  validates :chunk_type, :chunk_text, presence: true

  scope :with_embedding, -> { where.not(embedding: nil) }
end

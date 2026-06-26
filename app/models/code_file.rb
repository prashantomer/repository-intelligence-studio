class CodeFile < ApplicationRecord
  belongs_to :repository
  has_many :code_chunks, dependent: :destroy
  has_many :entities, dependent: :destroy

  validates :path, :language, :content_hash, presence: true
end

class Conversation < ApplicationRecord
  belongs_to :repository
  belongs_to :user, optional: true
  has_many :messages, dependent: :destroy

  validates :title, presence: true
end

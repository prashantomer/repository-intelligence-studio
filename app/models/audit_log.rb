class AuditLog < ApplicationRecord
  belongs_to :repository
  belongs_to :auditable, polymorphic: true, optional: true

  validates :event, presence: true
end

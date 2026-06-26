class EntityRelationship < ApplicationRecord
  belongs_to :repository
  belongs_to :source_entity, class_name: "Entity"
  belongs_to :target_entity, class_name: "Entity"

  validates :relationship_type, presence: true
end

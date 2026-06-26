class Entity < ApplicationRecord
  belongs_to :repository
  belongs_to :code_file
  has_many :outgoing_relationships, class_name: "EntityRelationship", foreign_key: :source_entity_id, dependent: :destroy
  has_many :incoming_relationships, class_name: "EntityRelationship", foreign_key: :target_entity_id, dependent: :destroy

  validates :entity_type, :name, presence: true
end

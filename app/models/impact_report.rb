class ImpactReport < ApplicationRecord
  belongs_to :repository

  validates :query, presence: true
  validates :generated_at, presence: true

  scope :recent_first, -> { order(generated_at: :desc, created_at: :desc) }

  def entity_name
    result_json.fetch("entity_name", "Unknown entity")
  end

  def risk_level
    result_json.fetch("risk_level", "unknown")
  end

  def summary
    result_json.fetch("summary", "")
  end

  def narration
    result_json.fetch("narration", "")
  end

  def checklist
    Array(result_json["checklist"])
  end

  def narration_source
    result_json.fetch("narration_source", "unknown")
  end

  def provider_error
    result_json["provider_error"]
  end

  def repository_profile
    result_json["repository_profile"] || {}
  end

  def entity_type
    result_json.fetch("entity_type", "entity")
  end

  def entity_path
    result_json.fetch("entity_path", "Unknown file")
  end

  def affected_entities_count
    Array(result_json["affected_entities"]).size
  end

  def impacted_files_count
    Array(result_json["impacted_files"]).size
  end

  def routes_count
    Array(result_json["routes"]).size
  end

  def jobs_count
    Array(result_json["jobs"]).size
  end

  def affected_entities
    Array(result_json["affected_entities"])
  end

  def impacted_files
    Array(result_json["impacted_files"])
  end

  def upstream_entities
    Array(result_json["upstream_entities"])
  end

  def downstream_entities
    Array(result_json["downstream_entities"])
  end

  def routes
    Array(result_json["routes"])
  end

  def jobs
    Array(result_json["jobs"])
  end

  def citations
    Array(result_json["citations"])
  end

  def self.available?
    connection.data_source_exists?(table_name)
  rescue ActiveRecord::ActiveRecordError, PG::Error
    false
  end
end

module Codebase
  class EntityRelationshipExtractorService < ApplicationService
    def initialize(repository:, root_path:)
      @repository = repository
      @root_path = root_path
    end

    def call
      relationships = []
      entities_by_file = repository.entities.includes(:code_file).group_by(&:code_file_id)
      entity_names = repository.entities.pluck(:name).uniq

      repository.code_files.find_each do |code_file|
        source_entities = entities_by_file[code_file.id] || []
        next if source_entities.empty?

        file_text = File.read(File.join(root_path, code_file.path))

        source_entities.each do |source_entity|
          entity_names.each do |target_name|
            next if target_name == source_entity.name
            next unless file_text.match?(/\b#{Regexp.escape(target_name)}\b/)

            target_entity = repository.entities.where(name: target_name).where.not(id: source_entity.id).first
            next unless target_entity

            relationships << repository.entity_relationships.find_or_create_by!(
              source_entity: source_entity,
              target_entity: target_entity,
              relationship_type: infer_relationship_type(source_entity, target_entity)
            )
          end
        end
      end

      ApplicationResult.success(data: relationships)
    end

    private

    attr_reader :repository, :root_path

    def infer_relationship_type(source_entity, target_entity)
      return "controller_calls_service" if source_entity.entity_type == "controller" && target_entity.entity_type == "service"
      return "service_uses_model" if source_entity.entity_type == "service" && target_entity.entity_type == "model"
      return "job_calls_service" if source_entity.entity_type == "job" && target_entity.entity_type == "service"

      "references"
    end
  end
end

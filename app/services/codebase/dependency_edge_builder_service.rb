module Codebase
  class DependencyEdgeBuilderService < ApplicationService
    def initialize(repository:)
      @repository = repository
    end

    def call
      edges = []

      ActiveRecord::Base.transaction do
        repository.dependency_edges.delete_all
        edges.concat(build_entity_relationship_edges)
        edges.concat(build_route_edges)
      end

      ApplicationResult.success(data: edges)
    end

    private

    attr_reader :repository

    def build_entity_relationship_edges
      repository.entity_relationships.find_each.map do |relationship|
        repository.dependency_edges.create!(
          source_type: "Entity",
          source_id: relationship.source_entity_id,
          target_type: "Entity",
          target_id: relationship.target_entity_id,
          edge_type: relationship.relationship_type,
          confidence: confidence_for_relationship(relationship.relationship_type)
        )
      end
    end

    def build_route_edges
      repository.repository_routes.filter_map do |route|
        controller_entity = match_controller_entity(route)
        next unless controller_entity

        repository.dependency_edges.create!(
          source_type: "RepositoryRoute",
          source_id: route.id,
          target_type: "Entity",
          target_id: controller_entity.id,
          edge_type: "route_to_controller",
          confidence: 0.95
        )
      end
    end

    def match_controller_entity(route)
      return if route.controller_name.blank?

      controller_name = "#{route.controller_name.to_s.camelize}Controller"
      repository.entities.find_by(name: controller_name, entity_type: "controller")
    end

    def confidence_for_relationship(relationship_type)
      case relationship_type
      when "controller_calls_service", "service_uses_model", "job_calls_service"
        0.9
      else
        0.65
      end
    end
  end
end

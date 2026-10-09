module DependencyGraph
  class TraversalQuery < ApplicationService
    DEFAULT_DEPTH = 3

    def initialize(repository:, entity_identifier:, depth: DEFAULT_DEPTH)
      @repository = repository
      @entity_identifier = entity_identifier.to_s.strip
      @depth = depth.to_i
    end

    def call
      return ApplicationResult.failure(error: "Entity cannot be blank") if entity_identifier.blank?
      return ApplicationResult.failure(error: "Dependency graph is not available yet for this repository") unless dependency_graph_available?

      entity = find_entity
      return ApplicationResult.failure(error: missing_entity_message) if entity.blank?

      upstream_entities = load_entities(ancestor_ids_for(entity.id))
      downstream_entities = load_entities(descendant_ids_for(entity.id))
      routes = load_routes_for(entity, upstream_entities)
      jobs = (upstream_entities + downstream_entities).select { |related_entity| related_entity.entity_type == "job" }.uniq(&:id)
      related_files = load_related_files(entity, upstream_entities, downstream_entities)

      ApplicationResult.success(
        data: {
          entity:,
          upstream_entities:,
          downstream_entities:,
          routes:,
          jobs:,
          related_files:,
          direct_upstream_edge_count: direct_upstream_edge_count(entity.id),
          direct_downstream_edge_count: direct_downstream_edge_count(entity.id)
        }
      )
    end

    private

    attr_reader :repository, :entity_identifier, :depth

    def sanitized_identifier
      @sanitized_identifier ||= entity_identifier.to_s.strip.gsub(/\A[`'"]+|[`'"]+\z/, "").strip
    end

    def dependency_graph_available?
      repository.respond_to?(:dependency_edges) && repository.dependency_edges.exists?
    end

    def find_entity
      repository.entities.find_by(id: sanitized_identifier).presence ||
        exact_name_match ||
        namespace_match ||
        file_basename_match ||
        partial_name_match
    end

    def exact_name_match
      repository.entities.where("LOWER(name) = ?", sanitized_identifier.downcase).first
    end

    def namespace_match
      repository.entities
                .where("LOWER(COALESCE(namespace || '::', '') || name) = ?", sanitized_identifier.downcase)
                .first
    end

    def file_basename_match
      basename = sanitized_identifier.downcase.sub(/\.[a-z0-9]+\z/, "")
      repository.entities.joins(:code_file)
                .where("LOWER(REPLACE(SPLIT_PART(code_files.path, '/', array_length(string_to_array(code_files.path, '/'), 1)), '.rb', '')) = ?", basename)
                .first
    rescue ActiveRecord::StatementInvalid
      nil
    end

    def partial_name_match
      term = "%#{sanitized_identifier.downcase}%"
      repository.entities
                .where("LOWER(name) LIKE ? OR LOWER(COALESCE(namespace || '::', '') || name) LIKE ?", term, term)
                .order(Arel.sql("LENGTH(name) ASC"))
                .first
    end

    def missing_entity_message
      matches = repository.entities
                          .where("LOWER(name) LIKE ?", "%#{sanitized_identifier.downcase}%")
                          .order(Arel.sql("LENGTH(name) ASC"))
                          .limit(5)
                          .pluck(:name)

      return "No matching entity found for `#{sanitized_identifier}`" if matches.empty?

      "No exact matching entity found for `#{sanitized_identifier}`. Try one of: #{matches.uniq.join(', ')}"
    end

    def ancestor_ids_for(entity_id)
      traverse_entity_ids(start_ids: [ entity_id ], direction: :upstream)
    end

    def descendant_ids_for(entity_id)
      traverse_entity_ids(start_ids: [ entity_id ], direction: :downstream)
    end

    def traverse_entity_ids(start_ids:, direction:)
      visited = start_ids.index_with { 0 }
      frontier = start_ids
      collected = []

      depth.times do |level|
        break if frontier.empty?

        edges = entity_edges_for(frontier, direction)
        next_ids = edges.map { |edge| next_entity_id(edge, direction) }.uniq.reject { |id| visited.key?(id) }

        next_ids.each { |id| visited[id] = level + 1 }
        collected.concat(next_ids)
        frontier = next_ids
      end

      collected
    end

    def entity_edges_for(entity_ids, direction)
      scope = repository.dependency_edges.where(source_type: "Entity", target_type: "Entity")

      case direction
      when :upstream
        scope.where(target_id: entity_ids)
      when :downstream
        scope.where(source_id: entity_ids)
      else
        DependencyEdge.none
      end
    end

    def next_entity_id(edge, direction)
      direction == :upstream ? edge.source_id : edge.target_id
    end

    def load_entities(entity_ids)
      entities_by_id = repository.entities.where(id: entity_ids).includes(:code_file).index_by(&:id)
      entity_ids.filter_map { |entity_id| entities_by_id[entity_id] }
    end

    def load_routes_for(entity, upstream_entities)
      controller_ids = ([ entity ] + upstream_entities).select { |related_entity| related_entity.entity_type == "controller" }.map(&:id).uniq
      return [] if controller_ids.empty?

      route_ids = repository.dependency_edges
                            .where(source_type: "RepositoryRoute", target_type: "Entity", edge_type: "route_to_controller", target_id: controller_ids)
                            .pluck(:source_id)

      repository.repository_routes.where(id: route_ids).order(:http_method, :path)
    end

    def load_related_files(entity, upstream_entities, downstream_entities)
      code_file_ids = ([ entity ] + upstream_entities + downstream_entities).map(&:code_file_id).compact.uniq
      repository.code_files.where(id: code_file_ids).order(:path)
    end

    def direct_upstream_edge_count(entity_id)
      repository.dependency_edges.where(source_type: "Entity", target_type: "Entity", target_id: entity_id).count
    end

    def direct_downstream_edge_count(entity_id)
      repository.dependency_edges.where(source_type: "Entity", target_type: "Entity", source_id: entity_id).count
    end
  end
end

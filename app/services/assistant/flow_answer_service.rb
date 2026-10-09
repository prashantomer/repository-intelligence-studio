module Assistant
  class FlowAnswerService < ApplicationService
    ENTITY_TYPE_PATTERNS = {
      "service" => /\b(service|services)\b/i,
      "controller" => /\b(controller|controllers)\b/i,
      "job" => /\b(job|jobs|worker|workers)\b/i,
      "model" => /\b(model|models)\b/i
    }.freeze

    FLOW_PATTERNS = [
      /\b(flow|sequence|pipeline|cycle|path)\b/i,
      /\b(involved|engagement|execution|call)\b/i
    ].freeze

    STOP_WORDS = %w[
      list all the a an in of for with and or to from on by involved engagement execution call cycle flow sequence
      pipeline path services service controllers controller jobs job workers worker models model classes class modules module
      what which show explain tell me more around within through
    ].freeze

    RELATIONSHIP_WEIGHTS = {
      "controller_calls_service" => 12,
      "job_calls_service" => 12,
      "service_uses_model" => 8,
      "references" => 5
    }.freeze

    def initialize(repository:, question:, conversation_context: nil)
      @repository = repository
      @question = question.to_s.strip
      @conversation_context = conversation_context || {}
    end

    def call
      return ApplicationResult.success(data: nil) unless flow_question?
      return ApplicationResult.success(data: nil) if requested_entity_type.blank?

      seed_entities = scored_entities.select { |item| item[:score].positive? }
      return ApplicationResult.success(data: nil) if seed_entities.empty?

      selected_entities = expand_entities(seed_entities)
      ordered_entities = order_entities(selected_entities)
      return ApplicationResult.success(data: nil) if ordered_entities.empty?

      citations = build_citations(ordered_entities)
      chunks = chunks_for_entities(ordered_entities)
      context_override = build_context_override(ordered_entities)

      answer_result = answer_service.call(
        repository:,
        question:,
        chunks:,
        conversation_context:,
        context_override:,
        citations_override: citations,
        extra_instructions: extra_instructions,
        request_metadata_override: {
          structured_mode: "flow",
          structured_entity_type: requested_entity_type,
          structured_entity_count: ordered_entities.size,
          focus_keywords: focus_keywords
        }
      )
      return answer_result if answer_result.failure?

      ApplicationResult.success(data: answer_result.data)
    end

    private

    attr_reader :repository, :question, :conversation_context

    def flow_question?
      FLOW_PATTERNS.any? { |pattern| question.match?(pattern) } &&
        ENTITY_TYPE_PATTERNS.any? { |_type, pattern| question.match?(pattern) }
    end

    def requested_entity_type
      @requested_entity_type ||= ENTITY_TYPE_PATTERNS.find { |_entity_type, pattern| question.match?(pattern) }&.first
    end

    def focus_keywords
      @focus_keywords ||= begin
        question.downcase
                .scan(/[a-z0-9_:-]+/)
                .reject { |token| STOP_WORDS.include?(token) }
                .flat_map { |token| keyword_variants(token) }
                .uniq
                .first(8)
      end
    end

    def keyword_variants(token)
      variants = [token]
      variants << token.singularize if token.respond_to?(:singularize)
      variants << token.pluralize if token.respond_to?(:pluralize)
      variants << token.sub(/ing\z/, "") if token.end_with?("ing")
      variants << token.sub(/ed\z/, "") if token.end_with?("ed")
      variants << token.sub(/es\z/, "") if token.end_with?("es")
      variants << token.sub(/s\z/, "") if token.end_with?("s")
      variants.reject(&:blank?).uniq
    end

    def scored_entities
      @scored_entities ||= repository.entities
                                   .includes(:code_file)
                                   .where(entity_type: requested_entity_type)
                                   .map do |entity|
        { entity:, score: entity_match_score(entity) }
      end
    end

    def entity_match_score(entity)
      haystacks = [
        entity.name.to_s.downcase,
        entity.namespace.to_s.downcase,
        entity.signature.to_s.downcase,
        entity.code_file&.path.to_s.downcase
      ]

      focus_keywords.sum do |keyword|
        score = 0
        score += 18 if haystacks[0].include?(keyword)
        score += 12 if haystacks[3].include?(keyword)
        score += 8 if haystacks[2].include?(keyword)
        score += 4 if haystacks[1].include?(keyword)
        score
      end
    end

    def expand_entities(seed_entities)
      entity_scores = seed_entities.index_by { |item| item[:entity].id }
      frontier_ids = entity_scores.keys

      2.times do
        related_relationships(frontier_ids).each do |relationship|
          [relationship.source_entity, relationship.target_entity].each do |entity|
            next unless entity.entity_type == requested_entity_type
            next unless entity.code_file.present?

            existing = entity_scores[entity.id]
            relationship_bonus = RELATIONSHIP_WEIGHTS.fetch(relationship.relationship_type, 3)
            derived_score = (existing&.fetch(:score, 0) || entity_match_score(entity)) + relationship_bonus

            entity_scores[entity.id] = { entity:, score: [derived_score, entity_match_score(entity)].max }
          end
        end

        frontier_ids = entity_scores.keys
      end

      entity_scores.values.sort_by { |item| [ -item[:score], item[:entity].name, item[:entity].code_file&.path.to_s ] }.first(12)
    end

    def related_relationships(entity_ids)
      repository.entity_relationships
                .includes(:source_entity, :target_entity)
                .where(source_entity_id: entity_ids)
                .or(
                  repository.entity_relationships.includes(:source_entity, :target_entity).where(target_entity_id: entity_ids)
                )
    end

    def order_entities(scored_items)
      entities_by_id = scored_items.index_by { |item| item[:entity].id }
      relationships = repository.entity_relationships
                                .where(source_entity_id: entities_by_id.keys, target_entity_id: entities_by_id.keys)
                                .to_a

      indegree = Hash.new(0)
      adjacency = Hash.new { |hash, key| hash[key] = [] }

      relationships.each do |relationship|
        adjacency[relationship.source_entity_id] << relationship.target_entity_id
        indegree[relationship.target_entity_id] += 1
        indegree[relationship.source_entity_id] ||= 0
      end

      queue = entities_by_id.keys.select { |id| indegree[id].zero? }
                                .sort_by { |id| [ -entities_by_id[id][:score], entities_by_id[id][:entity].code_file&.path.to_s ] }

      ordered_ids = []
      until queue.empty?
        current_id = queue.shift
        ordered_ids << current_id

        adjacency[current_id].each do |target_id|
          indegree[target_id] -= 1
          if indegree[target_id].zero?
            queue << target_id
            queue.sort_by! { |id| [ -entities_by_id[id][:score], entities_by_id[id][:entity].code_file&.path.to_s ] }
          end
        end
      end

      remaining_ids = entities_by_id.keys - ordered_ids
      ordered_ids.concat(remaining_ids.sort_by { |id| [ -entities_by_id[id][:score], entities_by_id[id][:entity].code_file&.path.to_s ] })

      ordered_ids.map { |id| entities_by_id[id][:entity] }
    end

    def build_context_override(entities)
      lines = []
      lines << "Structured flow evidence for: #{question}"
      lines << "Requested entity type: #{requested_entity_type}"
      lines << "Focus keywords: #{focus_keywords.join(', ')}" if focus_keywords.any?
      lines << ""
      lines << "Ordered modules/classes and file paths:"

      entities.each_with_index do |entity, index|
        line_number = entity.metadata_json&.fetch("line_number", nil) || entity.metadata_json&.fetch(:line_number, nil)
        declaration = entity.signature.to_s.presence || entity.name
        location = entity.code_file&.path.to_s
        location = "#{location}:#{line_number}" if line_number.present?

        lines << "#{index + 1}. #{qualified_name(entity)} — #{location}"
        lines << "   Declaration: #{declaration}"
      end

      lines << ""
      lines << "Relationship evidence:"
      relationships_for_entities(entities).first(20).each do |relationship|
        lines << "- #{qualified_name(relationship.source_entity)} --#{relationship.relationship_type}--> #{qualified_name(relationship.target_entity)}"
      end

      lines.join("\n")
    end

    def relationships_for_entities(entities)
      ids = entities.map(&:id)
      repository.entity_relationships
                .includes(:source_entity, :target_entity)
                .where(source_entity_id: ids, target_entity_id: ids)
                .order(:created_at)
                .to_a
    end

    def chunks_for_entities(entities)
      entity_ids = entities.map(&:id)
      repository.code_chunks
                .includes(:code_file, :entity)
                .where(entity_id: entity_ids)
                .order(:start_line)
                .to_a
                .uniq { |chunk| [chunk.entity_id, chunk.code_file_id, chunk.start_line] }
                .first(8)
    end

    def build_citations(entities)
      chunk_map = repository.code_chunks.includes(:code_file).where(entity_id: entities.map(&:id)).group_by(&:entity_id)

      entities.filter_map do |entity|
        chunk = chunk_map[entity.id]&.first
        next unless chunk.present?

        {
          path: chunk.code_file.path,
          start_line: chunk.start_line,
          end_line: chunk.end_line,
          chunk_type: chunk.chunk_type,
          entity_name: qualified_name(entity)
        }
      end.first(10)
    end

    def qualified_name(entity)
      [entity.namespace, entity.name].compact.join("::")
    end

    def answer_service
      return Assistant::LocalAnswerService if repository.assistant_provider_local?

      Assistant::ProviderAnswerService
    end

    def extra_instructions
      [
        "Answer in ordered sequence form.",
        "Preserve the exact module or class names and file paths from the structured evidence.",
        "Do not invent routes, services, or sequence steps not present in the structured evidence.",
        "If the flow is only partial, say that explicitly.",
        "Prefer concise bullets over long paragraphs."
      ]
    end
  end
end

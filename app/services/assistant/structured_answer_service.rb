module Assistant
  class StructuredAnswerService < ApplicationService
    ENTITY_TYPE_PATTERNS = {
      "service" => /\b(service|services)\b/i,
      "controller" => /\b(controller|controllers)\b/i,
      "job" => /\b(job|jobs|worker|workers)\b/i,
      "model" => /\b(model|models)\b/i
    }.freeze

    INVENTORY_PATTERNS = [
      /\A\s*(?:list|show|display|enumerate)\s+(?:all\s+)?(?:the\s+)?(services|controllers|jobs|workers|models)\s*\??\s*\z/i,
      /\A\s*what\s+(services|controllers|jobs|workers|models)\s+(?:exist|are\s+there|do\s+we\s+have)\s*\??\s*\z/i,
      /\A\s*which\s+(services|controllers|jobs|workers|models)\s+(?:exist|are\s+present)\s*\??\s*\z/i
    ].freeze

    SCOPING_PATTERNS = [
      /\binvolved\b/i,
      /\bused\b/i,
      /\brelated\b/i,
      /\bfor\b/i,
      /\bin\b/i,
      /\bwithin\b/i,
      /\bthrough\b/i,
      /\bcalled\b/i,
      /\bcalling\b/i,
      /\bflow\b/i,
      /\bcycle\b/i,
      /\bsequence\b/i,
      /\bengagement\b/i,
      /\bchunking\b/i,
      /\bindexing\b/i,
      /\bimpact\b/i,
      /\bwhere\b/i,
      /\bhow\b/i,
      /\bwhy\b/i
    ].freeze

    def initialize(repository:, question:)
      @repository = repository
      @question = question.to_s.strip
    end

    def call
      return ApplicationResult.success(data: nil) if question.blank?
      return ApplicationResult.success(data: nil) unless inventory_question?

      entity_type = requested_entity_type
      return ApplicationResult.success(data: nil) if entity_type.blank?

      entities = repository.entities
                           .includes(:code_file)
                           .where(entity_type:)
                           .order(:name)
                           .to_a

      return ApplicationResult.success(data: empty_payload(entity_type)) if entities.empty?

      answer = build_answer(entity_type, entities)

      ApplicationResult.success(
        data: {
          answer:,
          citations: build_citations(entities),
          prompt_tokens: approximate_tokens(question),
          completion_tokens: approximate_tokens(answer)
        }
      )
    end

    private

    attr_reader :repository, :question

    def inventory_question?
      INVENTORY_PATTERNS.any? { |pattern| question.match?(pattern) } && !scoped_inventory_question?
    end

    def requested_entity_type
      ENTITY_TYPE_PATTERNS.find { |_entity_type, pattern| question.match?(pattern) }&.first
    end

    def scoped_inventory_question?
      SCOPING_PATTERNS.any? { |pattern| question.match?(pattern) }
    end

    def build_answer(entity_type, entities)
      limited_entities = entities.first(50)
      noun = entity_type.pluralize

      lines = []
      lines << "Indexed #{noun} in #{repository.name}: #{entities.size}"
      lines << ""

      limited_entities.each_with_index do |entity, index|
        path = entity.code_file&.path || "unknown path"
        lines << "#{index + 1}. #{entity.name} — #{path}"
      end

      if entities.size > limited_entities.size
        lines << ""
        lines << "Showing first #{limited_entities.size} of #{entities.size} indexed #{noun}."
      end

      lines.join("\n")
    end

    def empty_payload(entity_type)
      noun = entity_type.pluralize

      {
        answer: "No indexed #{noun} were found in #{repository.name}. Re-sync the repository if you expect them to be present.",
        citations: [],
        prompt_tokens: approximate_tokens(question),
        completion_tokens: approximate_tokens(noun)
      }
    end

    def build_citations(entities)
      chunk_map = repository.code_chunks
                            .where(entity_id: entities.map(&:id))
                            .includes(:code_file)
                            .group_by(&:entity_id)

      entities.first(10).filter_map do |entity|
        chunk = chunk_map[entity.id]&.first
        next unless chunk.present?

        {
          path: chunk.code_file.path,
          start_line: chunk.start_line,
          end_line: chunk.end_line,
          chunk_type: chunk.chunk_type,
          entity_name: entity.name
        }
      end
    end

    def approximate_tokens(text)
      (text.to_s.length / 4.0).ceil
    end
  end
end

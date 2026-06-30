module Analysis
  class ImpactAnalysisService < ApplicationService
    def initialize(repository:, entity_identifier:)
      @repository = repository
      @entity_identifier = entity_identifier.to_s.strip
    end

    def call
      traversal_result = DependencyGraph::TraversalQuery.call(repository:, entity_identifier:)
      return traversal_result if traversal_result.failure?

      traversal = traversal_result.data
      entity = traversal.fetch(:entity)

      retrieval_result = Retrieval::SemanticSearchService.call(
        repository:,
        query: "What breaks if #{entity.name} changes?",
        limit: 6
      )
      return retrieval_result if retrieval_result.failure?

      chunks = retrieval_result.data
      upstream_entities = traversal.fetch(:upstream_entities)
      downstream_entities = traversal.fetch(:downstream_entities)
      affected_entities = (traversal.fetch(:downstream_entities) + traversal.fetch(:upstream_entities)).uniq(&:id)
      impacted_files = traversal.fetch(:related_files)
      risk_level = risk_level_for(traversal:, chunks:, affected_entities:, impacted_files:)
      summary = build_summary(entity:, traversal:, chunks:, affected_entities:, impacted_files:)
      citations = build_citations(chunks)
      narration_result = Analysis::ImpactNarrationService.call(
        repository:,
        entity:,
        summary:,
        risk_level:,
        upstream_entities:,
        downstream_entities:,
        impacted_files:,
        routes: traversal.fetch(:routes),
        jobs: traversal.fetch(:jobs),
        citations:
      )
      narration_payload = narration_result.success? ? narration_result.data : {
        narration: nil,
        checklist: [],
        source: "unavailable",
        provider_error: narration_result.error.to_s
      }
      impact_report = persist_report(
        entity:,
        traversal:,
        summary:,
        risk_level:,
        upstream_entities:,
        downstream_entities:,
        affected_entities:,
        impacted_files:,
        citations:,
        narration_payload:
      )

      ApplicationResult.success(
        data: {
          entity:,
          summary:,
          risk_level:,
          upstream_entities:,
          downstream_entities:,
          affected_entities:,
          impacted_files:,
          routes: traversal.fetch(:routes),
          jobs: traversal.fetch(:jobs),
          citations:,
          narration: narration_payload[:narration],
          checklist: narration_payload[:checklist],
          repository_profile: narration_payload[:repository_profile],
          narration_source: narration_payload[:source],
          provider_error: narration_payload[:provider_error],
          impact_report:
        impact_report
        }
      )
    end

    private

    attr_reader :repository, :entity_identifier

    def build_summary(entity:, traversal:, chunks:, affected_entities:, impacted_files:)
      direct_downstream = traversal.fetch(:direct_downstream_edge_count)
      direct_upstream = traversal.fetch(:direct_upstream_edge_count)
      routes = traversal.fetch(:routes)
      jobs = traversal.fetch(:jobs)

      lines = []
      lines << "#{entity.name} has #{direct_upstream} direct upstream dependencies and #{direct_downstream} direct downstream dependents in the current repository graph."

      if routes.any?
        lines << "This graph path is reachable from #{routes.size} route#{'s' unless routes.size == 1}, which raises change visibility at the API boundary."
      end

      if jobs.any?
        lines << "#{jobs.size} background job#{'s' unless jobs.size == 1} touch this area, so async side effects should be reviewed before changing it."
      end

      if affected_entities.any?
        entity_preview = affected_entities.first(5).map(&:name).join(", ")
        lines << "Likely affected entities include #{entity_preview}."
      end

      if impacted_files.any?
        file_preview = impacted_files.first(4).map(&:path).join(", ")
        lines << "Related files include #{file_preview}."
      end

      if chunks.any?
        top_chunk = chunks.first
        snippet = top_chunk.chunk_text.to_s.gsub(/\s+/, " ").strip.truncate(220)
        lines << "Top retrieved evidence is in #{top_chunk.code_file.path}:#{top_chunk.start_line}-#{top_chunk.end_line}, suggesting impact around #{top_chunk.chunk_type} logic. Snippet: #{snippet}"
      else
        lines << "No embedding-backed code evidence was retrieved, so this impact estimate is graph-only."
      end

      lines.join("\n\n")
    end

    def risk_level_for(traversal:, chunks:, affected_entities:, impacted_files:)
      score = 0
      score += traversal.fetch(:direct_downstream_edge_count) * 2
      score += traversal.fetch(:routes).size * 3
      score += traversal.fetch(:jobs).size * 2
      score += [ affected_entities.size, 6 ].min
      score += [ impacted_files.size / 2, 4 ].min
      score += 2 if chunks.any?

      case score
      when 0..4
        "low"
      when 5..11
        "medium"
      else
        "high"
      end
    end

    def build_citations(chunks)
      chunks.first(5).map do |chunk|
        {
          path: chunk.code_file.path,
          start_line: chunk.start_line,
          end_line: chunk.end_line,
          chunk_type: chunk.chunk_type,
          entity_name: chunk.entity&.name
        }
      end
    end

    def persist_report(entity:, traversal:, summary:, risk_level:, upstream_entities:, downstream_entities:, affected_entities:, impacted_files:, citations:, narration_payload:)
      return unless ImpactReport.available?

      repository.impact_reports.create!(
        query: entity_identifier,
        generated_at: Time.current,
        result_json: {
          entity_name: entity.name,
          entity_type: entity.entity_type,
          entity_path: entity.code_file.path,
          summary: summary,
          narration: narration_payload[:narration],
          checklist: narration_payload[:checklist],
          repository_profile: narration_payload[:repository_profile],
          narration_source: narration_payload[:source],
          provider_error: narration_payload[:provider_error],
          risk_level: risk_level,
          upstream_entities: upstream_entities.first(25).map do |related_entity|
            {
              name: related_entity.name,
              entity_type: related_entity.entity_type,
              path: related_entity.code_file.path
            }
          end,
          downstream_entities: downstream_entities.first(25).map do |related_entity|
            {
              name: related_entity.name,
              entity_type: related_entity.entity_type,
              path: related_entity.code_file.path
            }
          end,
          affected_entities: affected_entities.first(25).map do |related_entity|
            {
              name: related_entity.name,
              entity_type: related_entity.entity_type,
              path: related_entity.code_file.path
            }
          end,
          impacted_files: impacted_files.first(25).map do |code_file|
            {
              path: code_file.path,
              language: code_file.language
            }
          end,
          routes: traversal.fetch(:routes).first(25).map do |route|
            {
              method: route.http_method,
              path: route.path,
              controller: route.controller_name,
              action: route.action_name
            }
          end,
          jobs: traversal.fetch(:jobs).first(25).map do |job_entity|
            {
              name: job_entity.name,
              path: job_entity.code_file.path
            }
          end,
          citations: citations
        }
      )
    rescue ActiveRecord::ActiveRecordError
      nil
    end
  end
end

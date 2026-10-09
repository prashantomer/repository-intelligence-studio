module Analysis
  class ImpactNarrationService < ApplicationService
    SYSTEM_PROMPT = <<~PROMPT.freeze
      You are an engineering change-impact analyst.
      Use only the supplied repository evidence.
      Separate concrete evidence from inference.
      Keep the answer concise, practical, and review-oriented.
    PROMPT

    def initialize(repository:, entity:, summary:, risk_level:, upstream_entities:, downstream_entities:, impacted_files:, routes:, jobs:, citations:)
      @repository = repository
      @entity = entity
      @summary = summary
      @risk_level = risk_level
      @upstream_entities = upstream_entities
      @downstream_entities = downstream_entities
      @impacted_files = impacted_files
      @routes = routes
      @jobs = jobs
      @citations = citations
    end

    def call
      profile = repository_profile
      return deterministic_result("local") if repository.assistant_provider_local?

      client = Ai::ProviderFactory.for_assistant(repository)
      return deterministic_result("fallback_local") if client.blank?

      started_at = current_time_ms
      response = client.chat_completion(
        model: repository.assistant_model,
        system_prompt: SYSTEM_PROMPT,
        user_prompt: prompt_body
      )
      latency_ms = current_time_ms - started_at

      if response.failure?
        record_provider_call(status: :failed, latency_ms:, error_message: response.error)
        return deterministic_result("fallback_local", response.error)
      end

      payload = normalize_payload(response.data)
      narration = payload[:answer].presence || deterministic_narration
      checklist = deterministic_checklist

      record_provider_call(
        status: :success,
        latency_ms:,
        prompt_tokens: payload[:prompt_tokens],
        completion_tokens: payload[:completion_tokens],
        response_payload: response.data,
        narration:
      )

      ApplicationResult.success(
        data: {
          narration:,
          checklist:,
          repository_profile: profile,
          source: "provider",
          provider_error: nil
        }
      )
    end

    private

    attr_reader :repository, :entity, :summary, :risk_level, :upstream_entities, :downstream_entities, :impacted_files, :routes, :jobs, :citations

    def prompt_body
      profile = repository_profile

      <<~PROMPT
        Repository: #{repository.name}
        Repository profile: #{profile.fetch(:label)}
        Dominant languages: #{profile.fetch(:dominant_languages).presence&.join(", ") || "unknown"}
        Matched markers: #{profile.fetch(:matched_markers).presence&.join(", ") || "none"}
        Entity under review: #{entity.name}
        Risk level: #{risk_level}

        Deterministic summary:
        #{summary}

        Framework/language review focus:
        #{profile.fetch(:impact_focus).map { |item| "- #{item}" }.join("\n")}

        Upstream dependencies:
        #{entity_list(upstream_entities)}

        Downstream dependents:
        #{entity_list(downstream_entities)}

        Routes:
        #{route_list(routes)}

        Background jobs:
        #{job_list(jobs)}

        Impacted files:
        #{file_list(impacted_files)}

        Citations:
        #{citation_list(citations)}

        Instructions:
        - Explain why this change is risky or contained.
        - Give a short review checklist.
        - Mention uncertainty when evidence is incomplete.
        - Use markdown bullets.
      PROMPT
    end

    def deterministic_result(source, provider_error = nil)
      ApplicationResult.success(
        data: {
          narration: deterministic_narration(provider_error),
          checklist: deterministic_checklist,
          repository_profile: repository_profile,
          source: source,
          provider_error:
        }
      )
    end

    def deterministic_narration(provider_error = nil)
      profile = repository_profile
      lines = []
      lines << "## Impact reading"
      lines << "- **Repository profile:** #{profile.fetch(:label)}."
      lines << "- **Risk level:** #{risk_level.humanize}."
      lines << "- **Primary blast radius:** #{downstream_entities.first(4).map(&:name).presence&.join(', ') || 'No direct downstream dependents were found.'}"
      lines << "- **Change entry points:** #{routes.size} route#{'s' unless routes.size == 1} and #{jobs.size} job#{'s' unless jobs.size == 1} are connected to this area."
      lines << "- **Files to inspect first:** #{impacted_files.first(4).map(&:path).presence&.join(', ') || 'No related files were identified.'}"
      lines << "- **Profile-specific focus:** #{profile.fetch(:impact_focus).first(2).join(' Review ')}."
      lines << "- **Confidence:** #{citations.any? ? 'Semantic evidence and graph traversal both contributed.' : 'Graph traversal only; embedding evidence was limited.'}"
      lines << "- **Provider fallback:** #{provider_error}" if provider_error.present?
      lines.join("\n")
    end

    def deterministic_checklist
      profile = repository_profile
      checklist = []
      checklist << "Review direct downstream dependents before changing public method signatures." if downstream_entities.any?
      checklist << "Verify upstream assumptions and input contracts used by this entity." if upstream_entities.any?
      checklist << "Retest API or request flows that touch connected routes." if routes.any?
      checklist << "Check async side effects for connected jobs." if jobs.any?
      checklist << "Inspect the top impacted files for shared constants, callbacks, and branching logic." if impacted_files.any?
      checklist.concat(profile.fetch(:impact_focus).first(2).map { |focus| "Profile check: review #{focus}." })
      checklist.presence || [ "Review the entity implementation and nearby files manually; structured blast-radius evidence is limited." ]
    end

    def normalize_payload(data)
      case repository.assistant_provider
      when Repository::ASSISTANT_PROVIDERS[:openai]
        choice = data.fetch("choices", []).first || {}
        message = choice.fetch("message", {})
        usage = data.fetch("usage", {})
        {
          answer: message["content"].to_s.strip,
          prompt_tokens: usage["prompt_tokens"].to_i,
          completion_tokens: usage["completion_tokens"].to_i
        }
      when Repository::ASSISTANT_PROVIDERS[:anthropic]
        content = data.fetch("content", []).filter_map { |item| item["text"] }.join("\n").strip
        usage = data.fetch("usage", {})
        {
          answer: content,
          prompt_tokens: usage["input_tokens"].to_i,
          completion_tokens: usage["output_tokens"].to_i
        }
      when Repository::ASSISTANT_PROVIDERS[:ollama]
        message = data.fetch("message", {})
        {
          answer: message["content"].to_s.strip,
          prompt_tokens: data["prompt_eval_count"].to_i,
          completion_tokens: data["eval_count"].to_i
        }
      else
        { answer: "", prompt_tokens: 0, completion_tokens: 0 }
      end
    end

    def record_provider_call(status:, latency_ms:, prompt_tokens: 0, completion_tokens: 0, response_payload: {}, narration: nil, error_message: nil)
      Ai::ProviderCallLogRecorder.call(
        repository:,
        user: repository.user,
        provider: repository.assistant_provider,
        operation_type: :impact_analysis,
        model: repository.assistant_model,
        endpoint: assistant_endpoint,
        request_metadata: {
          entity_name: entity.name,
          risk_level:,
          upstream_count: upstream_entities.size,
          downstream_count: downstream_entities.size,
          impacted_file_count: impacted_files.size,
          route_count: routes.size,
          job_count: jobs.size
        },
        response_metadata: {
          response_keys: response_payload.respond_to?(:keys) ? response_payload.keys : [],
          narration_chars: narration.to_s.length,
          checklist_count: deterministic_checklist.size
        },
        prompt_tokens:,
        completion_tokens:,
        latency_ms:,
        status:,
        error_message:
      )
    end

    def assistant_endpoint
      case repository.assistant_provider
      when Repository::ASSISTANT_PROVIDERS[:openai]
        "/v1/chat/completions"
      when Repository::ASSISTANT_PROVIDERS[:anthropic]
        "/v1/messages"
      when Repository::ASSISTANT_PROVIDERS[:ollama]
        "/api/chat"
      else
        "local"
      end
    end

    def entity_list(entities)
      entities.first(10).map { |record| "#{record.name} (#{record.entity_type} · #{record.code_file.path})" }.join("\n")
    end

    def route_list(route_records)
      route_records.first(10).map { |route| "#{route.http_method} #{route.path} -> #{[ route.controller_name, route.action_name ].compact.join('#')}" }.join("\n")
    end

    def job_list(job_records)
      job_records.first(10).map { |job| "#{job.name} (#{job.code_file.path})" }.join("\n")
    end

    def file_list(file_records)
      file_records.first(10).map { |file| "#{file.path} (#{file.language})" }.join("\n")
    end

    def citation_list(citation_records)
      citation_records.first(10).map { |citation| "#{citation[:path]}:#{citation[:start_line]}-#{citation[:end_line]} (#{citation[:chunk_type]})" }.join("\n")
    end

    def current_time_ms
      Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)
    end

    def repository_profile
      @repository_profile ||= begin
        result = Codebase::RepositoryProfileService.call(repository:)
        result.success? ? result.data : fallback_profile
      end
    end

    def fallback_profile
      {
        key: "generic",
        label: "Generic Repository",
        dominant_languages: [],
        impact_focus: [
          "primary entrypoints, shared modules, and dependency boundaries",
          "background or async execution paths",
          "public contracts, schemas, or reusable library surfaces"
        ],
        matched_markers: []
      }
    end
  end
end

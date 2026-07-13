module Assistant
  class ProviderAnswerService < ApplicationService
    SYSTEM_PROMPT = <<~PROMPT.freeze
      You are a repository-scoped engineering assistant.
      Answer only from the supplied repository context.
      If the context is insufficient, say that directly.
      Cite files and line ranges inline when possible.
    PROMPT

    def initialize(repository:, question:, chunks:, conversation_context: nil)
      @repository = repository
      @question = question
      @chunks = chunks
      @conversation_context = conversation_context || {}
    end

    def call
      client = Ai::ProviderFactory.for_assistant(repository)
      return ApplicationResult.failure(error: "Unsupported assistant provider") if client.blank?

      started_at = current_time_ms
      response = client.chat_completion(
        model: repository.assistant_model,
        system_prompt: SYSTEM_PROMPT,
        user_prompt: prompt_body
      )
      latency_ms = current_time_ms - started_at

      if response.failure?
        record_provider_call(status: :failed, latency_ms:, error_message: response.error)
        return contextual_failure(response.error)
      end

      payload = normalize_payload(response.data)
      record_provider_call(
        status: :success,
        latency_ms:,
        prompt_tokens: payload[:prompt_tokens],
        completion_tokens: payload[:completion_tokens],
        response_payload: response.data,
        answer: payload[:answer]
      )

      ApplicationResult.success(
        data: {
          answer: payload[:answer],
          citations: build_citations,
          prompt_tokens: payload[:prompt_tokens],
          completion_tokens: payload[:completion_tokens]
        }
      )
    end

    private

    attr_reader :repository, :question, :chunks, :conversation_context

    def prompt_body
      <<~PROMPT
        Repository: #{repository.name}
        Assistant provider: #{repository.assistant_provider}
        Current user question: #{question}

        Recent conversation context:
        #{conversation_context.fetch(:prompt_transcript, "No prior conversation context.")}

        Retrieval search input:
        #{conversation_context.fetch(:retrieval_query, question)}

        Indexed repository context:
        #{ContextFormatter.call(chunks:)}

        Instructions:
        - Use recent conversation only to resolve follow-up references.
        - Use indexed repository context as the source of truth.
        - If the thread refers to something not supported by the retrieved context, say that directly.
      PROMPT
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
        {
          answer: "",
          prompt_tokens: 0,
          completion_tokens: 0
        }
      end
    end

    def build_citations
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

    def contextual_failure(error_message)
      ApplicationResult.failure(
        error: "Assistant provider #{repository.assistant_provider} failed for model #{repository.assistant_model}: #{error_message}"
      )
    end

    def record_provider_call(status:, latency_ms:, prompt_tokens: 0, completion_tokens: 0, response_payload: {}, answer: nil, error_message: nil)
      Ai::ProviderCallLogRecorder.call(
        repository:,
        user: repository.user,
        provider: repository.assistant_provider,
        operation_type: :assistant,
        model: repository.assistant_model,
        endpoint: assistant_endpoint,
        request_metadata: {
          question_preview: question.to_s.squish.truncate(280),
          question_chars: question.to_s.length,
          retrieval_query_chars: conversation_context.fetch(:retrieval_query, question).to_s.length,
          recent_message_count: conversation_context.fetch(:recent_messages, []).size,
          chunk_count: chunks.size,
          top_paths: chunks.first(5).map { |chunk| chunk.code_file.path }
        },
        response_metadata: {
          response_keys: response_payload.respond_to?(:keys) ? response_payload.keys : [],
          answer_chars: answer.to_s.length,
          citation_count: build_citations.size
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

    def current_time_ms
      Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)
    end
  end
end

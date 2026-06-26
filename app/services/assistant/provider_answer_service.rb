module Assistant
  class ProviderAnswerService < ApplicationService
    SYSTEM_PROMPT = <<~PROMPT.freeze
      You are a repository-scoped engineering assistant.
      Answer only from the supplied repository context.
      If the context is insufficient, say that directly.
      Cite files and line ranges inline when possible.
    PROMPT

    def initialize(repository:, question:, chunks:)
      @repository = repository
      @question = question
      @chunks = chunks
    end

    def call
      client = Ai::ProviderFactory.for_assistant(repository)
      return ApplicationResult.failure(error: "Unsupported assistant provider") if client.blank?

      response = client.chat_completion(
        model: repository.assistant_model,
        system_prompt: SYSTEM_PROMPT,
        user_prompt: prompt_body
      )
      return contextual_failure(response.error) if response.failure?

      payload = normalize_payload(response.data)

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

    attr_reader :repository, :question, :chunks

    def prompt_body
      <<~PROMPT
        Repository: #{repository.name}
        Assistant provider: #{repository.assistant_provider}
        Question: #{question}

        Indexed repository context:
        #{ContextFormatter.call(chunks:)}
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
  end
end

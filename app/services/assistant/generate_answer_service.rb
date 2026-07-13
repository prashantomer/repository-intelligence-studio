module Assistant
  class GenerateAnswerService < ApplicationService
    def initialize(repository:, question:, conversation: nil, pending_message: nil)
      @repository = repository
      @question = question.to_s.strip
      @conversation = conversation
      @pending_message = pending_message
    end

    def call
      return ApplicationResult.failure(error: "Question cannot be blank") if question.blank?

      conversation_context_result = Assistant::ConversationContextService.call(
        question:,
        conversation:,
        pending_message:
      )
      return conversation_context_result if conversation_context_result.failure?

      conversation_context = conversation_context_result.data

      retrieval_result = Retrieval::SemanticSearchService.call(
        repository:,
        query: conversation_context[:retrieval_query]
      )
      return retrieval_result if retrieval_result.failure?

      answer_result = answer_service.call(
        repository:,
        question:,
        chunks: retrieval_result.data,
        conversation_context:
      )
      answer_result = fallback_local_answer(retrieval_result.data, answer_result.error) if answer_result.failure?
      return answer_result if answer_result.failure?

      ApplicationResult.success(
        data: {
          payload: answer_result.data,
          retrieved_chunks: retrieval_result.data
        }
      )
    end

    private

    attr_reader :repository, :question, :conversation, :pending_message

    def answer_service
      return LocalAnswerService if repository.assistant_provider_local?

      ProviderAnswerService
    end

    def fallback_local_answer(chunks, error_message)
      conversation_context = Assistant::ConversationContextService.call(
        question:,
        conversation:,
        pending_message:
      ).data

      result = LocalAnswerService.call(
        repository:,
        question:,
        chunks:,
        conversation_context:
      )
      return result if result.failure?

      payload = result.data
      payload[:answer] = "Configured provider fallback: #{error_message}\n\n#{payload[:answer]}"
      ApplicationResult.success(data: payload)
    end
  end
end

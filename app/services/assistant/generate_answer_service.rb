module Assistant
  class GenerateAnswerService < ApplicationService
    def initialize(repository:, question:)
      @repository = repository
      @question = question.to_s.strip
    end

    def call
      return ApplicationResult.failure(error: "Question cannot be blank") if question.blank?

      retrieval_result = Retrieval::SemanticSearchService.call(repository:, query: question)
      return retrieval_result if retrieval_result.failure?

      answer_result = answer_service.call(
        repository:,
        question:,
        chunks: retrieval_result.data
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

    attr_reader :repository, :question

    def answer_service
      return LocalAnswerService if repository.assistant_provider_local?

      ProviderAnswerService
    end

    def fallback_local_answer(chunks, error_message)
      result = LocalAnswerService.call(repository:, question:, chunks:)
      return result if result.failure?

      payload = result.data
      payload[:answer] = "Configured provider fallback: #{error_message}\n\n#{payload[:answer]}"
      ApplicationResult.success(data: payload)
    end
  end
end

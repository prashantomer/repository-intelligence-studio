module Assistant
  class AnswerQuestionService < ApplicationService
    def initialize(repository:, question:, conversation: nil)
      @repository = repository
      @question = question.to_s.strip
      @conversation = conversation
    end

    def call
      return ApplicationResult.failure(error: "Question cannot be blank") if question.blank?

      conversation_record = conversation || repository.conversations.create!(title: derive_title, user: repository.user)
      conversation_record.messages.create!(role: :user, content: question, response_state: :completed)

      generation_result = GenerateAnswerService.call(repository:, question:)
      return generation_result if generation_result.failure?

      payload = generation_result.data.fetch(:payload)
      assistant_message = conversation_record.messages.create!(
        role: :assistant,
        content: payload[:answer],
        cites_json: payload[:citations],
        prompt_tokens: payload[:prompt_tokens],
        completion_tokens: payload[:completion_tokens],
        response_state: :completed
      )

      ApplicationResult.success(
        data: {
          conversation: conversation_record,
          message: assistant_message,
          retrieved_chunks: generation_result.data.fetch(:retrieved_chunks)
        }
      )
    end

    private

    attr_reader :repository, :question, :conversation

    def derive_title
      question.truncate(60)
    end
  end
end

module Assistant
  class QueueQuestionService < ApplicationService
    def initialize(repository:, question:, conversation: nil)
      @repository = repository
      @question = question.to_s.strip
      @conversation = conversation
    end

    def call
      return ApplicationResult.failure(error: "Question cannot be blank") if question.blank?

      conversation_record = conversation || repository.conversations.create!(title: derive_title, user: repository.user)
      user_message = conversation_record.messages.create!(
        role: :user,
        content: question,
        response_state: :completed
      )
      assistant_message = conversation_record.messages.create!(
        role: :assistant,
        content: "Assistant is thinking…",
        response_state: :pending
      )

      AssistantResponseJob.perform_later(
        repository.id,
        conversation_record.id,
        assistant_message.id,
        question
      )

      ApplicationResult.success(
        data: {
          conversation: conversation_record,
          user_message:,
          assistant_message:
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

class AssistantResponseJob < ApplicationJob
  queue_as :default

  def perform(repository_id, conversation_id, assistant_message_id, question)
    repository = Repository.find(repository_id)
    conversation = repository.conversations.find(conversation_id)
    assistant_message = conversation.messages.find(assistant_message_id)

    result = Assistant::GenerateAnswerService.call(
      repository:,
      question:,
      conversation:,
      pending_message: assistant_message
    )

    if result.success?
      payload = result.data.fetch(:payload)
      assistant_message.update!(
        content: payload[:answer],
        cites_json: payload[:citations],
        prompt_tokens: payload[:prompt_tokens],
        completion_tokens: payload[:completion_tokens],
        response_state: :completed
      )
    else
      assistant_message.update!(
        content: "Assistant request failed: #{result.error}",
        cites_json: [],
        prompt_tokens: 0,
        completion_tokens: 0,
        response_state: :failed
      )
    end

    broadcast_message(repository, assistant_message)
  rescue ActiveRecord::RecordNotFound
    Rails.logger.info("AssistantResponseJob skipped missing record for repository #{repository_id}")
  rescue StandardError => e
    if assistant_message.present?
      assistant_message.update_columns(
        content: "Assistant request failed: #{e.message}",
        response_state: "failed",
        updated_at: Time.current
      )
      broadcast_message(repository, assistant_message) if repository.present?
    end
    raise
  end

  private

  def broadcast_message(repository, message)
    Turbo::StreamsChannel.broadcast_replace_to(
      [ repository, :assistant ],
      target: ActionView::RecordIdentifier.dom_id(message),
      partial: "repositories/assistant/message",
      locals: { message:, repository: }
    )
  end
end

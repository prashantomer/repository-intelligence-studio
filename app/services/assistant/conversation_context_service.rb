module Assistant
  class ConversationContextService < ApplicationService
    MAX_PROMPT_MESSAGES = 6
    FOLLOW_UP_PATTERN = /
      \A(
        and\b|
        also\b|
        what\ about\b|
        how\ about\b|
        what\ else\b|
        explain\ more\b|
        tell\ me\ more\b|
        why\b|
        where\b|
        when\b|
        how\b|
        it\b|
        this\b|
        that\b|
        they\b|
        those\b|
        these\b
      )
    /ix.freeze

    def initialize(question:, conversation: nil, pending_message: nil)
      @question = question.to_s.strip
      @conversation = conversation
      @pending_message = pending_message
    end

    def call
      ApplicationResult.success(
        data: {
          recent_messages:,
          retrieval_query:,
          prompt_transcript:
        }
      )
    end

    private

    attr_reader :question, :conversation, :pending_message

    def recent_messages
      @recent_messages ||= begin
        return [] if conversation.blank?

        messages = conversation.messages
                               .where.not(id: pending_message&.id)
                               .order(created_at: :asc)
                               .to_a

        if messages.last&.user? && normalized(messages.last.content) == normalized(question)
          messages = messages[0...-1]
        end

        messages.last(MAX_PROMPT_MESSAGES)
      end
    end

    def retrieval_query
      return question if recent_messages.empty?

      anchors = []
      previous_user_question = recent_messages.reverse.find(&:user?)
      previous_assistant_answer = recent_messages.reverse.find(&:assistant?)

      if likely_follow_up?
        anchors << "Previous user question: #{truncate_text(previous_user_question&.content, 220)}" if previous_user_question.present?
        anchors << "Previous assistant answer: #{truncate_text(previous_assistant_answer&.content, 320)}" if previous_assistant_answer.present?
      elsif short_question? && previous_user_question.present?
        anchors << "Previous user question: #{truncate_text(previous_user_question.content, 220)}"
      end

      ([ question ] + anchors).join("\n")
    end

    def prompt_transcript
      return "No prior conversation context." if recent_messages.empty?

      recent_messages.map do |message|
        "#{message.role.to_s.capitalize}: #{truncate_text(message.content, 900)}"
      end.join("\n\n")
    end

    def likely_follow_up?
      short_question? || question.match?(FOLLOW_UP_PATTERN)
    end

    def short_question?
      question.split.size <= 7
    end

    def truncate_text(text, limit)
      text.to_s.squish.truncate(limit)
    end

    def normalized(text)
      text.to_s.squish.downcase
    end
  end
end

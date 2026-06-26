class Message < ApplicationRecord
  belongs_to :conversation

  enum :role,
       {
         user: "user",
         assistant: "assistant"
       },
       validate: true

  enum :response_state,
       {
         pending: "pending",
         completed: "completed",
         failed: "failed"
       },
       prefix: true,
       validate: true

  validates :content, presence: true

  def citations
    cites_json
  end

  def pending_response?
    assistant? && response_state_pending?
  end

  def failed_response?
    assistant? && response_state_failed?
  end
end

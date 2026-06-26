module AuditLogs
  class RecordService < ApplicationService
    def initialize(repository:, event:, auditable: nil, message: nil, metadata: {})
      @repository = repository
      @event = event
      @auditable = auditable
      @message = message
      @metadata = metadata
    end

    def call
      repository.audit_logs.create!(
        event:,
        auditable:,
        message:,
        metadata:
      )
    end

    private

    attr_reader :repository, :event, :auditable, :message, :metadata
  end
end

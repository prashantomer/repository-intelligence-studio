module RepositoryIngestions
  class StartService < ApplicationService
    def initialize(repository:, triggered_by_id: nil, force: false)
      @repository = repository
      @triggered_by_id = triggered_by_id
      @force = force
    end

    def call
      active = repository.active_ingestion
      release_stale_ingestion!(active) if active&.stale?
      active = repository.active_ingestion
      return ApplicationResult.failure(error: active) if active.present?

      ingestion = repository.repository_ingestions.create!(
        branch_name: repository.tracked_branch,
        status: :pending,
        triggered_by_id:,
        force_rebuild: force?
      )

      repository.update!(status: :pending)

      AuditLogs::RecordService.call(
        repository:,
        auditable: ingestion,
        event: "repository.ingestion.queued",
        message: "Repository ingestion queued",
        metadata: { branch_name: ingestion.branch_name, force_rebuild: ingestion.force_rebuild? }
      )

      RepositoryIngestionJob.perform_later(ingestion.id)

      ApplicationResult.success(data: ingestion)
    end

    private

    attr_reader :repository, :triggered_by_id

    def force?
      @force
    end

    def release_stale_ingestion!(ingestion)
      timestamp = Time.current
      previous_status = ingestion.status

      ingestion.update!(
        status: :failed,
        finished_at: timestamp,
        error_message: "Automatically released as stale before queueing a new ingestion."
      )

      repository.update!(status: :failed) if repository.active_ingestion.blank?

      AuditLogs::RecordService.call(
        repository:,
        auditable: ingestion,
        event: "repository.ingestion.released_stale",
        message: "Stale ingestion released automatically before re-sync",
        metadata: {
          branch_name: ingestion.branch_name,
          previous_status: previous_status,
          stale_after_seconds: RepositoryIngestion::STALE_AFTER.to_i
        }
      )
    end
  end
end

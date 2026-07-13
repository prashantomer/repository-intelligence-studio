module Repositories
  class DestroyService < ApplicationService
    require "fileutils"

    def initialize(repository:, deletion_reason: "user_requested")
      @repository = repository
      @deletion_reason = deletion_reason
    end

    def call
      repository.with_lock do
        return ApplicationResult.failure(error: "Repository deletion already recorded.") if RepositoryDeletionLog.exists?(deleted_repository_id: repository.id)

        snapshot = build_snapshot
        deletion_log = nil

        ApplicationRecord.transaction do
          deletion_log = RepositoryDeletionLog.create!(snapshot.except(:workspace_pathname))
          repository.destroy!
        end

        cleanup_result = cleanup_workspace!(snapshot[:workspace_pathname])
        deletion_log.update_column(:summary_json, deletion_log.summary.merge(cleanup_result.stringify_keys))

        ApplicationResult.success(data: deletion_log)
      end
    rescue ActiveRecord::RecordNotUnique
      ApplicationResult.failure(error: "Repository deletion already recorded.")
    rescue ActiveRecord::RecordNotDestroyed, ActiveRecord::RecordInvalid => e
      ApplicationResult.failure(error: e.message)
    end

    private

    attr_reader :repository, :deletion_reason

    def build_snapshot
      active_ingestion = repository.active_ingestion
      workspace_pathname = repository_workspace_path
      message_count = Message.joins(:conversation).where(conversations: { repository_id: repository.id }).count

      summary = {
        ingestion_count: repository.repository_ingestions.count,
        audit_log_count: repository.audit_logs.count,
        code_file_count: repository.code_files.count,
        code_chunk_count: repository.code_chunks.count,
        entity_count: repository.entities.count,
        entity_relationship_count: repository.entity_relationships.count,
        route_count: repository.repository_routes.count,
        conversation_count: repository.conversations.count,
        message_count: message_count,
        provider_call_log_count: repository.provider_call_logs.count,
        dependency_edge_count: repository.dependency_edges.count,
        impact_report_count: repository.impact_reports.count,
        active_ingestion_present: active_ingestion.present?,
        workspace_path: workspace_pathname.to_s,
        workspace_existed: workspace_pathname.exist?,
        workspace_cleanup_success: false
      }

      {
        deleted_repository_id: repository.id,
        user_id: repository.user_id,
        name: repository.name,
        github_url: repository.github_url,
        provider: repository.provider,
        visibility: repository.visibility,
        default_branch: repository.default_branch,
        tracked_branch: repository.tracked_branch,
        status: repository.status,
        last_commit_sha: repository.last_commit_sha,
        last_ingested_at: repository.last_ingested_at,
        assistant_provider: repository.assistant_provider,
        assistant_model: repository.assistant_model,
        embedding_provider: repository.embedding_provider,
        embedding_model: repository.embedding_model,
        deleted_at: Time.current,
        deletion_reason:,
        summary_json: summary,
        workspace_pathname:
      }
    end

    def repository_workspace_path
      Pathname.new(Rails.configuration.x.eka.repository_workspace_root).join("repository-#{repository.id}")
    end

    def cleanup_workspace!(workspace_pathname)
      existed = workspace_pathname.exist?
      FileUtils.rm_rf(workspace_pathname) if existed
      {
        workspace_path: workspace_pathname.to_s,
        workspace_existed: existed,
        workspace_cleanup_success: !workspace_pathname.exist?
      }
    rescue StandardError => e
      Rails.logger.warn("Repository destroy cleanup failed for #{workspace_pathname}: #{e.message}")
      {
        workspace_path: workspace_pathname.to_s,
        workspace_existed: existed,
        workspace_cleanup_success: false
      }
    end
  end
end

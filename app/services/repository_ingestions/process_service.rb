module RepositoryIngestions
  class ProcessService < ApplicationService
    require "fileutils"

    def initialize(repository_ingestion_id:)
      @repository_ingestion = RepositoryIngestion.find(repository_ingestion_id)
      @repository = repository_ingestion.repository
    end

    def call
      workspace_path = clone_target_path
      return already_processed_result unless claim_execution!

      mark_cloning!

      metadata_result = Repositories::RemoteMetadataFetcher.call(repository:)
      return fail_ingestion!(metadata_result.error) if metadata_result.failure?

      remote_metadata = metadata_result.data
      apply_remote_defaults!(remote_metadata)

      if !repository_ingestion.force_rebuild? &&
         repository.last_commit_sha.present? &&
         repository.last_commit_sha == remote_metadata[:head_sha] &&
         repository.embedding_settings_aligned?
        skip_ingestion!(remote_metadata[:head_sha])
        return ApplicationResult.success(data: repository_ingestion)
      end

      clone_result = Repositories::CloneService.call(
        repository:,
        branch_name: repository_ingestion.branch_name,
        target_path: workspace_path
      )
      return fail_ingestion!(clone_result.error) if clone_result.failure?

      parse_result = parse_repository!(clone_result.data[:target_path])
      return fail_ingestion!(parse_result.error) if parse_result.failure?

      complete_ingestion!(remote_metadata[:head_sha], clone_result.data[:target_path], parse_result.data)
      ApplicationResult.success(data: repository_ingestion)
    rescue StandardError => e
      fail_ingestion!(e.message)
    ensure
      cleanup_workspace!(workspace_path)
    end

    private

    attr_reader :repository_ingestion, :repository

    def claim_execution!
      repository_ingestion.with_lock do
        repository_ingestion.reload
        return false unless repository_ingestion.processable?

        true
      end
    end

    def already_processed_result
      ApplicationResult.success(data: repository_ingestion)
    end

    def mark_cloning!
      repository_ingestion.update!(status: :cloning, started_at: Time.current, error_message: nil)
      repository.update!(status: :cloning)
    end

    def apply_remote_defaults!(remote_metadata)
      previous_default_branch = repository.default_branch
      previous_tracked_branch = repository.tracked_branch
      next_tracked_branch = if previous_tracked_branch.blank? || previous_tracked_branch == previous_default_branch
        remote_metadata[:default_branch]
      else
        previous_tracked_branch
      end

      repository.update!(
        default_branch: remote_metadata[:default_branch].presence || repository.default_branch,
        tracked_branch: next_tracked_branch
      )
      repository_ingestion.update!(branch_name: repository.tracked_branch)
    end

    def skip_ingestion!(head_sha)
      timestamp = Time.current
      repository_ingestion.update!(status: :skipped, commit_sha: head_sha, finished_at: timestamp)
      repository.update!(status: :skipped, last_ingested_at: timestamp, last_commit_sha: head_sha)

      AuditLogs::RecordService.call(
        repository:,
        auditable: repository_ingestion,
        event: "repository.ingestion.skipped",
        message: "Repository already ingested at latest commit",
        metadata: { branch_name: repository_ingestion.branch_name, commit_sha: head_sha }
      )
    end

    def fail_ingestion!(error_message)
      repository_ingestion.update!(status: :failed, finished_at: Time.current, error_message:)
      repository.update!(status: :failed)

      AuditLogs::RecordService.call(
        repository:,
        auditable: repository_ingestion,
        event: "repository.ingestion.failed",
        message: "Repository ingestion failed",
        metadata: { branch_name: repository_ingestion.branch_name, error: error_message }
      )

      ApplicationResult.failure(error: error_message)
    end

    def clone_target_path
      Pathname.new(Rails.configuration.x.eka.repository_workspace_root)
        .join("repository-#{repository.id}", "ingestion-#{repository_ingestion.id}")
    end

    def cleanup_workspace!(workspace_path)
      return if workspace_path.blank?

      FileUtils.rm_rf(workspace_path)
      cleanup_repository_workspace_root!(workspace_path.parent)
    rescue StandardError => e
      Rails.logger.warn("Repository ingestion cleanup failed for #{workspace_path}: #{e.message}")
    end

    def cleanup_repository_workspace_root!(repository_workspace_path)
      return unless repository_workspace_path.exist?
      return unless repository_workspace_path.children.empty?

      Dir.rmdir(repository_workspace_path)
    end

    def parse_repository!(target_path)
      repository_ingestion.update!(status: :parsing)
      repository.update!(status: :parsing)

      result = Codebase::IndexRepositoryService.call(repository:, root_path: target_path)
      return result if result.failure?

      embedding_result = embed_repository!
      return embedding_result if embedding_result.failure?

      AuditLogs::RecordService.call(
        repository:,
        auditable: repository_ingestion,
        event: "repository.ingestion.parsed",
        message: "Repository metadata indexed",
        metadata: result.data.merge(branch_name: repository_ingestion.branch_name)
      )

      result
    end

    def complete_ingestion!(head_sha, target_path, parse_metadata)
      timestamp = Time.current
      repository_ingestion.update!(status: :completed, commit_sha: head_sha, finished_at: timestamp)
      repository.update!(status: :completed, last_ingested_at: timestamp, last_commit_sha: head_sha)

      AuditLogs::RecordService.call(
        repository:,
        auditable: repository_ingestion,
        event: "repository.ingestion.completed",
        message: "Repository cloned and indexed successfully",
        metadata: {
          branch_name: repository_ingestion.branch_name,
          commit_sha: head_sha,
          force_rebuild: repository_ingestion.force_rebuild?,
          cloned_to: target_path,
          code_files_count: parse_metadata[:code_files_count],
          chunks_count: parse_metadata[:chunks_count],
          entities_count: parse_metadata[:entities_count],
          routes_count: parse_metadata[:routes_count]
        }
      )
    end

    def embed_repository!
      repository_ingestion.update!(status: :embedding)
      repository.update!(status: :embedding)

      result = Embeddings::GenerateChunkEmbeddingsService.call(repository:)
      return result if result.failure?

      AuditLogs::RecordService.call(
        repository:,
        auditable: repository_ingestion,
        event: "repository.ingestion.embedded",
        message: "Repository chunk embeddings generated",
        metadata: { embedded_chunks_count: result.data.size }
      )

      result
    end
  end
end

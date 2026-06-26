class RepositoryIngestionJob < ApplicationJob
  def perform(repository_ingestion_id)
    RepositoryIngestions::ProcessService.call(repository_ingestion_id:)
  rescue ActiveRecord::RecordNotFound
    Rails.logger.info("RepositoryIngestionJob skipped missing ingestion #{repository_ingestion_id}")
  end
end

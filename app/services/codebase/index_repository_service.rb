module Codebase
  class IndexRepositoryService < ApplicationService
    def initialize(repository:, root_path:)
      @repository = repository
      @root_path = root_path
    end

    def call
      ActiveRecord::Base.transaction do
        purge_existing_index!

        file_result = FileInventoryService.call(repository:, root_path:)
        return file_result if file_result.failure?

        entities = extract_entities_for_files!(file_result.data)
        routes = RoutesExtractorService.call(repository:, root_path:).data
        relationships = EntityRelationshipExtractorService.call(repository:, root_path:).data
        chunks = ChunkingService.call(repository:, root_path:).data

        ApplicationResult.success(
          data: {
            code_files_count: file_result.data.size,
            entities_count: entities.size,
            routes_count: routes.size,
            relationships_count: relationships.size,
            chunks_count: chunks.size
          }
        )
      end
    rescue StandardError => e
      ApplicationResult.failure(error: e.message)
    end

    private

    attr_reader :repository, :root_path

    def purge_existing_index!
      # Delete in order: leaf → root to respect FK dependencies
      repository.repository_routes.delete_all
      repository.code_chunks.delete_all
      repository.entity_relationships.delete_all
      repository.entities.delete_all
      repository.code_files.delete_all
    end

    def extract_entities_for_files!(code_files)
      code_files.flat_map do |code_file|
        Codebase::EntityExtractorRegistry.extractors_for(code_file).flat_map do |extractor|
          extractor.call(
            code_file:,
            absolute_path: File.join(root_path, code_file.path)
          ).data
        end
      end
    end
  end
end

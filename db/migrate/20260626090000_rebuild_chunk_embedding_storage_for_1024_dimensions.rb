class RebuildChunkEmbeddingStorageFor1024Dimensions < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL
      DROP INDEX IF EXISTS index_code_chunks_on_embedding
    SQL

    execute <<~SQL
      UPDATE code_chunks
      SET embedding = NULL
    SQL

    execute <<~SQL
      ALTER TABLE code_chunks
      ALTER COLUMN embedding TYPE vector(1024)
    SQL

    execute <<~SQL
      CREATE INDEX index_code_chunks_on_embedding
      ON code_chunks
      USING hnsw (embedding vector_cosine_ops)
    SQL

    execute <<~SQL
      UPDATE repositories
      SET indexed_embedding_provider = NULL,
          indexed_embedding_model = NULL
    SQL
  end

  def down
    execute <<~SQL
      DROP INDEX IF EXISTS index_code_chunks_on_embedding
    SQL

    execute <<~SQL
      UPDATE code_chunks
      SET embedding = NULL
    SQL

    execute <<~SQL
      ALTER TABLE code_chunks
      ALTER COLUMN embedding TYPE vector(1536)
    SQL

    execute <<~SQL
      CREATE INDEX index_code_chunks_on_embedding
      ON code_chunks
      USING hnsw (embedding vector_cosine_ops)
    SQL
  end
end

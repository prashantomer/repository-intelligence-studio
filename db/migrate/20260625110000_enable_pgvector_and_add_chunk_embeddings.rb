class EnablePgvectorAndAddChunkEmbeddings < ActiveRecord::Migration[8.1]
  def change
    enable_extension "vector" unless extension_enabled?("vector")

    reversible do |dir|
      dir.up do
        execute <<~SQL
          ALTER TABLE code_chunks
          ADD COLUMN embedding vector(1536)
        SQL

        execute <<~SQL
          CREATE INDEX index_code_chunks_on_embedding
          ON code_chunks
          USING hnsw (embedding vector_cosine_ops)
        SQL
      end

      dir.down do
        execute <<~SQL
          DROP INDEX IF EXISTS index_code_chunks_on_embedding
        SQL

        remove_column :code_chunks, :embedding
      end
    end
  end
end

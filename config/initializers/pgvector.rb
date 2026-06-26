ActiveSupport.on_load(:active_record) do
  begin
    require "pgvector"
    require "pgvector/active_record"
  rescue LoadError
    Rails.logger.warn("pgvector gem is not available")
  end
end

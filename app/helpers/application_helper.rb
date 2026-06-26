module ApplicationHelper
  def assistant_model_catalog_json
    AiModelCatalog::ASSISTANT_MODELS.to_json
  end

  def embedding_model_catalog_json
    AiModelCatalog::EMBEDDING_MODELS.to_json
  end
end

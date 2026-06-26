Rails.application.configure do
  config.x.eka.redis_url = ENV.fetch("REDIS_URL", "redis://localhost:6379/1")
  config.x.eka.openai_api_key = ENV["OPENAI_API_KEY"]
  config.x.eka.repository_workspace_root = ENV.fetch(
    "REPOSITORY_WORKSPACE_ROOT",
    Rails.root.join("tmp", "repositories").to_s
  )
end

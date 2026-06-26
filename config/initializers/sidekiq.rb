if defined?(Sidekiq)
  redis_url = ENV.fetch("REDIS_URL", "redis://localhost:6379/1")
  log_path = Rails.root.join("log", "sidekiq.log")

  Sidekiq.configure_server do |config|
    config.redis = { url: redis_url }
    logger = if ENV["SIDEKIQ_LOG_TO_STDOUT"] == "true"
      ActiveSupport::Logger.new($stdout)
    else
      ActiveSupport::Logger.new(log_path)
    end

    logger.level = Logger::DEBUG
    logger.formatter = proc do |severity, datetime, _progname, message|
      rendered_message = message.to_s
      next "" if ENV["SIDEKIQ_LOG_ACTIVEJOB_DUPLICATES"] != "true" && rendered_message.start_with?("[ActiveJob]")

      "[#{datetime.utc.iso8601}] #{severity} Sidekiq -- #{rendered_message}\n"
    end

    config.logger = ActiveSupport::TaggedLogging.new(logger)
  end

  Sidekiq.configure_client do |config|
    config.redis = { url: redis_url }
  end
end

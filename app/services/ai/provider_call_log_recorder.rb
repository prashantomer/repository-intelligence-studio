module Ai
  class ProviderCallLogRecorder < ApplicationService
    def initialize(repository:, user:, provider:, operation_type:, model:, endpoint: nil, request_metadata: {}, response_metadata: {}, prompt_tokens: 0, completion_tokens: 0, latency_ms: 0, status:, error_message: nil)
      @repository = repository
      @user = user
      @provider = provider
      @operation_type = operation_type
      @model = model
      @endpoint = endpoint
      @request_metadata = request_metadata || {}
      @response_metadata = response_metadata || {}
      @prompt_tokens = prompt_tokens.to_i
      @completion_tokens = completion_tokens.to_i
      @latency_ms = latency_ms.to_i
      @status = status
      @error_message = error_message
    end

    def call
      ProviderCallLog.create!(
        repository:,
        user:,
        provider:,
        operation_type:,
        model:,
        endpoint:,
        request_metadata:,
        response_metadata:,
        prompt_tokens:,
        completion_tokens:,
        total_tokens: prompt_tokens + completion_tokens,
        latency_ms:,
        estimated_cost_usd: Ai::CostEstimator.estimate(
          provider:,
          model:,
          prompt_tokens:,
          completion_tokens:
        ),
        status:,
        error_message:
      )
    rescue StandardError => error
      Rails.logger.warn("ProviderCallLogRecorder failed for #{provider}/#{operation_type}/#{model}: #{error.message}")
      nil
    end

    private

    attr_reader :repository, :user, :provider, :operation_type, :model, :endpoint, :request_metadata, :response_metadata, :prompt_tokens, :completion_tokens, :latency_ms, :status, :error_message
  end
end

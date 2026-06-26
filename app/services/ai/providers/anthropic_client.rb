module Ai
  module Providers
    class AnthropicClient < ApplicationService
      BASE_URL = "https://api.anthropic.com".freeze
      API_VERSION = "2023-06-01".freeze

      def initialize(api_key: ENV["ANTHROPIC_API_KEY"])
        @api_key = api_key.to_s
      end

      def chat_completion(model:, system_prompt:, user_prompt:)
        return missing_key_failure if api_key.blank?

        HttpJsonClient.call(
          base_url: BASE_URL,
          path: "/v1/messages",
          headers: {
            "x-api-key" => api_key,
            "anthropic-version" => API_VERSION
          },
          body: {
            model:,
            max_tokens: 1200,
            system: system_prompt,
            messages: [
              { role: "user", content: user_prompt }
            ]
          }
        )
      end

      private

      attr_reader :api_key

      def missing_key_failure
        ApplicationResult.failure(error: "ANTHROPIC_API_KEY is not configured")
      end
    end
  end
end

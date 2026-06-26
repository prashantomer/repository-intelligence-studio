module Ai
  module Providers
    class OpenaiClient < ApplicationService
      BASE_URL = "https://api.openai.com".freeze

      def initialize(api_key: ENV["OPENAI_API_KEY"])
        @api_key = api_key.to_s
      end

      def chat_completion(model:, system_prompt:, user_prompt:)
        return missing_key_failure if api_key.blank?

        HttpJsonClient.call(
          base_url: BASE_URL,
          path: "/v1/chat/completions",
          headers: authorization_headers,
          body: {
            model:,
            messages: [
              { role: "system", content: system_prompt },
              { role: "user", content: user_prompt }
            ],
            temperature: 0.1
          }
        )
      end

      def embedding(model:, text:)
        return missing_key_failure if api_key.blank?

        HttpJsonClient.call(
          base_url: BASE_URL,
          path: "/v1/embeddings",
          headers: authorization_headers,
          body: {
            model:,
            input: text
          }
        )
      end

      private

      attr_reader :api_key

      def authorization_headers
        { "Authorization" => "Bearer #{api_key}" }
      end

      def missing_key_failure
        ApplicationResult.failure(error: "OPENAI_API_KEY is not configured")
      end
    end
  end
end

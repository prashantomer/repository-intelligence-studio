module Ai
  module Providers
    class OllamaClient < ApplicationService
      def initialize(base_url:)
        @base_url = base_url
      end

      def chat_completion(model:, system_prompt:, user_prompt:)
        HttpJsonClient.call(
          base_url:,
          path: "/api/chat",
          headers: {},
          body: {
            model:,
            stream: false,
            messages: [
              { role: "system", content: system_prompt },
              { role: "user", content: user_prompt }
            ]
          }
        )
      end

      def embedding(model:, text:)
        HttpJsonClient.call(
          base_url:,
          path: "/api/embed",
          headers: {},
          body: {
            model:,
            input: text
          }
        )
      end

      private

      attr_reader :base_url
    end
  end
end

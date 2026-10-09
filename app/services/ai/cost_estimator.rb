module Ai
  class CostEstimator
    PRICE_BOOK = {
      "openai" => {
        "gpt-4.1-mini" => { input_per_million: 0.40, output_per_million: 1.60 },
        "gpt-4.1" => { input_per_million: 2.00, output_per_million: 8.00 },
        "gpt-4o-mini" => { input_per_million: 0.15, output_per_million: 0.60 },
        "text-embedding-3-small" => { input_per_million: 0.02, output_per_million: 0.0 },
        "text-embedding-3-large" => { input_per_million: 0.13, output_per_million: 0.0 }
      },
      "anthropic" => {
        "claude-3-5-haiku-latest" => { input_per_million: 0.80, output_per_million: 4.00 },
        "claude-3-5-sonnet-latest" => { input_per_million: 3.00, output_per_million: 15.00 },
        "claude-3-7-sonnet-latest" => { input_per_million: 3.00, output_per_million: 15.00 }
      },
      "ollama" => {},
      "local" => {}
    }.freeze

    def self.estimate(provider:, model:, prompt_tokens:, completion_tokens:)
      pricing = PRICE_BOOK.fetch(provider.to_s, {})[model.to_s]
      return 0.0 if provider.to_s.in?(%w[ollama local])
      return nil if pricing.blank?

      input_cost = (prompt_tokens.to_i / 1_000_000.0) * pricing[:input_per_million]
      output_cost = (completion_tokens.to_i / 1_000_000.0) * pricing[:output_per_million]
      (input_cost + output_cost).round(6)
    end
  end
end

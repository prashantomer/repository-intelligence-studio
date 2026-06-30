module Analysis
  class ImpactQueryInterpreterService < ApplicationService
    PATTERNS = [
      /what breaks if (?:the )?(?<target>.+?)(?: changes?| is changed)?(?:\?|$)/i,
      /if i (?:modify|change|update|remove|touch) (?:the )?(?<target>.+?)(?:,| what| which|\?|$)/i,
      /which files depend on (?:the )?(?<target>.+?)(?: class| module| service| method| function)?(?:\?|$)/i,
      /what apis use (?:the )?(?<target>.+?)(?: method| function)?(?:\?|$)/i,
      /show me all routes that touch (?:the )?(?<target>.+?)(?:\?|$)/i,
      /what jobs depend on (?:the )?(?<target>.+?)(?:\?|$)/i,
      /list all entities related to (?<target>.+?)(?:\?|$)/i,
      /what does (?:the )?(?<target>.+?) depend on(?:\?|$)/i,
      /upstream dependencies of (?:the )?(?<target>.+?)(?:\?|$)/i,
      /downstream (?:components|dependents) (?:are affected )?(?:if|by) (?:the )?(?<target>.+?)(?: changes?)?(?:\?|$)/i,
      /analy(?:s|z)e (?:the )?impact of (?<target>.+?)(?:\?|$)/i,
      /what'?s the risk of changing (?:the )?(?<target>.+?)(?:\?|$)/i
    ].freeze

    STRIP_TERMS = /\b(class|module|service|method|function|model|controller|job|worker|serializer|table)\b/i.freeze

    def initialize(repository:, query:)
      @repository = repository
      @query = query.to_s.strip
    end

    def call
      return ApplicationResult.failure(error: "Impact query cannot be blank") if query.blank?

      resolved_identifier = extract_target

      ApplicationResult.success(
        data: {
          raw_query: query,
          entity_identifier: resolved_identifier.presence || normalized_query,
          interpreted: resolved_identifier.present?
        }
      )
    end

    private

    attr_reader :repository, :query

    def normalized_query
      @normalized_query ||= query.gsub(/\A[`'"]+|[`'"]+\z/, "").strip
    end

    def extract_target
      candidate = pattern_match_target || direct_entity_name_match || normalized_query
      cleanup_target(candidate)
    end

    def pattern_match_target
      match = PATTERNS.lazy.map { |pattern| normalized_query.match(pattern) }.find(&:present?)
      match&.named_captures&.fetch("target", nil)
    end

    def direct_entity_name_match
      names = repository.entities.order(Arel.sql("LENGTH(name) DESC")).limit(200).pluck(:name)
      names.find { |name| normalized_query.downcase.include?(name.downcase) }
    end

    def cleanup_target(candidate)
      candidate.to_s
               .gsub(/\A[`'"]+|[`'"]+\z/, "")
               .gsub(STRIP_TERMS, "")
               .gsub(/\b(the|a|an|current implementation of|database schema for)\b/i, " ")
               .gsub(/[?.,]/, " ")
               .squish
               .presence
    end
  end
end

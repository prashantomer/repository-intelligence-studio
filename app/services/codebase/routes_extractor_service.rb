module Codebase
  class RoutesExtractorService < ApplicationService
    ROUTE_PATTERN = /^\s*(get|post|put|patch|delete)\s+["']([^"']+)["'](?:.*to:\s*["']([^#"' ]+)#([^"' ]+)["'])?/.freeze

    def initialize(repository:, root_path:)
      @repository = repository
      @root_path = Pathname.new(root_path)
    end

    def call
      routes_path = root_path.join("config", "routes.rb")
      return ApplicationResult.success(data: []) unless routes_path.exist?

      routes = []

      File.foreach(routes_path) do |line|
        match = line.match(ROUTE_PATTERN)
        next unless match

        routes << repository.repository_routes.create!(
          http_method: match[1].upcase,
          path: match[2],
          controller_name: match[3],
          action_name: match[4]
        )
      end

      ApplicationResult.success(data: routes)
    end

    private

    attr_reader :repository, :root_path
  end
end

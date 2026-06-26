require "json"
require "net/http"
require "uri"

module Ai
  class HttpJsonClient < ApplicationService
    def initialize(base_url:, path:, headers:, body:)
      @base_url = base_url
      @path = path
      @headers = headers
      @body = body
    end

    def call
      uri = URI.join(ensure_trailing_slash(base_url), normalized_path)
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      headers.each { |key, value| request[key] = value }
      request.body = JSON.generate(body)

      response = Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl: uri.scheme == "https",
        read_timeout: 60,
        open_timeout: 10
      ) do |http|
        http.request(request)
      end

      parsed = response.body.present? ? JSON.parse(response.body) : {}
      return ApplicationResult.success(data: parsed) if response.is_a?(Net::HTTPSuccess)

      ApplicationResult.failure(
        error: parsed["error"].presence || parsed["message"].presence || "HTTP #{response.code}"
      )
    rescue JSON::ParserError => error
      ApplicationResult.failure(error: "Invalid JSON response: #{error.message}")
    rescue StandardError => error
      ApplicationResult.failure(error: error.message)
    end

    private

    attr_reader :base_url, :path, :headers, :body

    def ensure_trailing_slash(value)
      value.end_with?("/") ? value : "#{value}/"
    end

    def normalized_path
      path.start_with?("/") ? path.delete_prefix("/") : path
    end
  end
end

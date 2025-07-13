# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'

module Deepsearch
  module SearchAdapters
    # An adapter for the Serper Search API (google.serper.dev).
    class SerperAdapter
      BASE_URL = 'https://google.serper.dev/search'

      def initialize(api_key = nil)
        @api_key = api_key || Deepsearch.configuration.serper_api_key
        validate_api_key!
      end

      # @param query [String] The search query
      # @param options [Hash] Additional search options
      # @option options [Integer] :max_results Maximum number of results to return. Serper calls this `num`.
      # @return [Hash] Parsed and transformed response from Serper API
      # @raise [SerperError] If the API request fails
      def search(query, options = {})
        raise ArgumentError, "Query cannot be empty" if query.nil? || query.strip.empty?

        payload = build_payload(query, options)
        response = make_request(payload)
        parsed_response = parse_response(response)
        transform_response(parsed_response)
      rescue Net::HTTPError, Net::ReadTimeout, Net::OpenTimeout => e
        raise SerperError, "Network error: #{e.message}"
      rescue JSON::ParserError => e
        raise SerperError, "Invalid JSON response: #{e.message}"
      end

      private

      def validate_api_key!
        raise SerperError, "API key is required" if @api_key.nil? || @api_key.strip.empty?
      end

      def build_payload(query, options)
        payload = {
          q: query
        }
        # Tavily uses `max_results`, Serper uses `num`. Let's support `max_results` from options.
        payload[:num] = options[:max_results] if options[:max_results]
        payload
      end

      def make_request(payload)
        uri = URI(BASE_URL)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.read_timeout = 15
        http.open_timeout = 5

        request = Net::HTTP::Post.new(uri)
        request['Content-Type'] = 'application/json'
        request['X-API-KEY'] = @api_key
        request.body = payload.to_json

        response = http.request(request)

        handle_error_response(response) unless response.is_a?(Net::HTTPSuccess)

        response
      end

      def parse_response(response)
        JSON.parse(response.body)
      rescue JSON::ParserError => e
        raise SerperError, "Failed to parse response: #{e.message}"
      end

      def transform_response(response_body)
        results = response_body['organic']&.map do |item|
          {
            'url' => item['link'],
            'title' => item['title'],
            'content' => item['snippet']
          }
        end || []
        { 'results' => results }
      end

      def handle_error_response(response)
        case response.code.to_i
        when 400
          raise SerperError, "Bad request: #{response.body}"
        when 401, 402
          raise SerperError, "Unauthorized or payment required: #{response.body}"
        when 429
          raise SerperError, "Rate limit exceeded"
        when 500..599
          raise SerperError, "Server error: #{response.code}"
        else
          raise SerperError, "HTTP error: #{response.code} - #{response.body}"
        end
      end
    end

    # Custom error class for exceptions raised by the SerperAdapter.
    class SerperError < StandardError; end
  end
end

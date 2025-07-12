# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'

module Deepsearch
  module SearchAdapters
    # An adapter for the Tavily Search API.
    class TavilyAdapter
      BASE_URL = 'https://api.tavily.com/search'

      def initialize(api_key = nil)
        @api_key = api_key || Deepsearch.configuration.tavily_api_key
        validate_api_key!
      end

      # @param query [String] The search query
      # @param options [Hash] Additional search options
      # @option options [Integer] :max_results Maximum number of results (default: 10)
      # @option options [Array<String>] :include_domains Domains to include in search
      # @option options [Array<String>] :exclude_domains Domains to exclude from search
      # @option options [Boolean] :include_answer Whether to include AI-generated answer (default: true)
      # @option options [Boolean] :include_raw_content Whether to include raw content (default: false)
      # @option options [String] :search_depth Search depth: 'basic' or 'advanced' (default: 'basic')
      # @return [Hash] Parsed response from Tavily API
      # @raise [TavilyError] If the API request fails
      def search(query, options = {})
        raise ArgumentError, "Query cannot be empty" if query.nil? || query.strip.empty?

        payload = build_payload(query, options)
        response = make_request(payload)
        parse_response(response)
      rescue Net::HTTPError, Net::ReadTimeout, Net::OpenTimeout => e
        raise TavilyError, "Network error: #{e.message}"
      rescue JSON::ParserError => e
        raise TavilyError, "Invalid JSON response: #{e.message}"
      end

      private

      def validate_api_key!
        if @api_key.nil? || @api_key.strip.empty?
          raise TavilyError, "API key is required"
        end

        unless @api_key.start_with?('tvly-')
          raise TavilyError, "Invalid API key format. Expected format: tvly-YOUR_API_KEY"
        end
      end

      def build_payload(query, options)
        payload = {
          query: query,
          max_results: options[:max_results] || 10,
          include_answer: options.fetch(:include_answer, true),
          include_raw_content: options.fetch(:include_raw_content, false),
          search_depth: options[:search_depth] || 'basic'
        }

        payload[:include_domains] = options[:include_domains] if options[:include_domains]
        payload[:exclude_domains] = options[:exclude_domains] if options[:exclude_domains]

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
        request['Authorization'] = "Bearer #{@api_key}"
        request.body = payload.to_json

        response = http.request(request)

        unless response.is_a?(Net::HTTPSuccess)
          handle_error_response(response)
        end

        response
      end

      def parse_response(response)
        JSON.parse(response.body)
      rescue JSON::ParserError => e
        raise TavilyError, "Failed to parse response: #{e.message}"
      end

      def handle_error_response(response)
        case response.code.to_i
        when 400
          raise TavilyError, "Bad request: #{response.body}"
        when 401
          raise TavilyError, "Unauthorized: Invalid API key"
        when 429
          raise TavilyError, "Rate limit exceeded"
        when 500..599
          raise TavilyError, "Server error: #{response.code}"
        else
          raise TavilyError, "HTTP error: #{response.code} - #{response.body}"
        end
      end
    end

    # Custom error class for exceptions raised by the TavilyAdapter.
    class TavilyError < StandardError; end
  end
end

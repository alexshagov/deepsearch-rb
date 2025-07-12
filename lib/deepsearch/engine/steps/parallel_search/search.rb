# frozen_string_literal: true

require 'async'
require 'async/semaphore'

module Deepsearch
  class Engine
    module Steps
      module ParallelSearch
        # Performs concurrent web searches for a list of queries using a given search adapter.
        # It manages concurrency, retries with exponential backoff for failed searches,
        # and aggregates the unique results.
        class Search
          MAX_CONCURRENCY = 2
          MAX_RETRIES = 1
          INITIAL_BACKOFF = 1

          def initialize(initial_query, sub_queries, search_adapter, **options)
            @all_queries = [initial_query] + sub_queries
            @search_adapter = search_adapter
            @max_total_search_results = options[:max_total_search_results]
            @search_options = build_search_options
            @logger = Deepsearch.configuration.logger
          end

          def output
            return [] if @all_queries.empty?

            results = perform_all_searches
            results.flatten.uniq { |result| result['url'] }
          end

          private

          def build_search_options
            return {} unless @max_total_search_results

            max_results_per_search = (@max_total_search_results.to_f / @all_queries.size).ceil
            { max_results: max_results_per_search }
          end

          def perform_all_searches
            @logger.debug("Starting parallel search for #{@all_queries.size} queries with max concurrency of #{MAX_CONCURRENCY}")

            Sync do |task|
              semaphore = Async::Semaphore.new(MAX_CONCURRENCY, parent: task)
              
              tasks = @all_queries.each_with_index.map do |query, index|
                # Add a small delay for subsequent tasks to avoid overwhelming the search api
                sleep(1) if index > 0
                
                semaphore.async do |sub_task|
                  sub_task.annotate("query ##{index + 1}: #{query}")
                  perform_search_with_retries(query, index + 1)
                end
              end

              tasks.map(&:wait)
            end
          end

          def perform_search_with_retries(query, query_number)
            (MAX_RETRIES + 1).times do |attempt|
              @logger.debug("Task #{query_number}: Searching '#{query}' (Attempt #{attempt + 1})")
              
              results = @search_adapter.search(query, @search_options)
              extracted = extract_results(results)
              @logger.debug("✓ Task #{query_number} completed with #{extracted.size} results for '#{query}'")
              return extracted

            rescue StandardError => e
              @logger.debug("✗ Task #{query_number} error for '#{query}': #{e.message}")
              
              break if attempt >= MAX_RETRIES

              sleep_duration = (INITIAL_BACKOFF * (2**attempt)) + rand(0.1..0.5)
              @logger.debug("   Retrying Task #{query_number} in #{sleep_duration.round(2)}s...")
              sleep(sleep_duration)
            end

            @logger.error("✗ Task #{query_number} failed permanently for '#{query}' after #{MAX_RETRIES} retries.")
            []
          end

          def extract_results(results)
            return [] if results.nil?
            return results unless results.is_a?(Hash)

            results['results'] || results[:results] || []
          end
        end
      end
    end
  end
end
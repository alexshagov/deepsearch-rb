# frozen_string_literal: true

require_relative 'result'
require_relative 'search'

module Deepsearch
  class Engine
    module Steps
      module ParallelSearch
        # Orchestrates the parallel execution of multiple search queries (initial query + sub-queries).
        # It uses the `Search` class to perform the actual concurrent searches via a search adapter
        # and wraps the outcome in a `Result` object.
        class Process
          attr_reader :initial_query, :sub_queries, :search_adapter, :options

          def initialize(initial_query:,
                         sub_queries:,
                         search_adapter:,
                         **options)
            @initial_query = initial_query
            @sub_queries = sub_queries
            @search_adapter = search_adapter
            @options = options
          end

          def execute
            websites = Search.new(initial_query, sub_queries, search_adapter, **@options).output
            Deepsearch.configuration.logger.debug("Parallel search completed with #{websites.size} results")
            ParallelSearch::Result.new(
              websites: websites
            )
          rescue StandardError => e
            ParallelSearch::Result.new(
              websites: [],
              error: e.message
            )
          end
        end
      end
    end
  end
end

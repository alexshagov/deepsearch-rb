# frozen_string_literal: true

require_relative "steps/prepare_subqueries/process"
require_relative "steps/parallel_search/process"
require_relative "steps/data_aggregation/process"
require_relative "steps/rag/process"
require_relative "steps/summarization/process"

module Deepsearch
  class Engine
    # Orchestrates the entire multi-step search and summarization process.
    # The pipeline executes a sequence of steps:
    # 1. Prepares sub-queries from the initial query.
    # 2. Performs parallel searches to gather website links.
    # 3. Aggregates and parses content from the found websites.
    # 4. Uses RAG to find text chunks relevant to the query.
    # 5. Summarizes the relevant chunks into a final answer.
    # It includes retry logic for each step to enhance robustness.
    class Pipeline
      def initialize(search_adapter)
        @search_adapter = search_adapter
      end

      def execute(query, **options)
        query_preprocessing_result = with_retry do
          Steps::PrepareSubqueries::Process.new(query).execute
        end
        notify_listener(:step_completed, step: :prepare_subqueries, result: query_preprocessing_result)
        # [query_preprocessing_result] Contains:
        #   - cleaned_query [String] The sanitized version of original query
        #   - original_query [String] The unmodified input query
        #   - sub_queries [Array<String>] Generated subqueries (empty array on error)
        #   - error [String, nil] Error message if processing failed

        parallel_search_options = {
          initial_query: query_preprocessing_result.cleaned_query,
          sub_queries: query_preprocessing_result.sub_queries,
          search_adapter: @search_adapter,
          **options
        }

        parallel_search_result = with_retry { Steps::ParallelSearch::Process.new(**parallel_search_options).execute }
        notify_listener(:step_completed, step: :parallel_search, result: parallel_search_result)
        # [parallel_search_result] Contains:
        #   - websites [Array<ParallelSearch::Result>] Search results
        #     - ParallelSearch::Result objects with:
        #       - websites [Array<Hash#url>] Array of website URLs
        #   - success [Boolean] Whether search succeeded
        #   - error [String, nil] Error message if search failed

        data_aggregation_result = with_retry do
          Steps::DataAggregation::Process.new(
            websites: parallel_search_result.websites
          ).execute
        end
        notify_listener(:step_completed, step: :data_aggregation, result: data_aggregation_result)
        # [data_aggregation_result] Contains:
        #   - parsed_websites [Array<DataAggregation::Result>]
        #     - DataAggregation::Result objects with:
        #       - url [String] Website URL
        #       - content [String] Parsed content from the website
        #   - success [Boolean] Whether search succeeded
        #   - error [String, nil] Error message if search failed

        rag_result = with_retry do
          Steps::Rag::Process.new(
            query: query_preprocessing_result.cleaned_query,
            parsed_websites: data_aggregation_result.parsed_websites
          ).execute
        end
        notify_listener(:step_completed, step: :rag, result: rag_result)
        # [rag_result] Contains:
        #   - query [::Deepsearch::Engine::Steps::Rag::Values::Query]
        #   - relevant_chunks [Array<::Deepsearch::Engine::Steps::Rag::Values::Chunk>]
        summarization_result = with_retry do
          Steps::Summarization::Process.new(
            query: rag_result.query,
            relevant_chunks: rag_result.relevant_chunks
          ).execute
        end
        notify_listener(:step_completed, step: :summarization, result: summarization_result)
        # [summarization_result] Contains:
        #   - summary [String] The final answer with citations
        #   - success [Boolean]
        #   - error [String, nil]

        summarization_result
      end

      private

      def notify_listener(event, **payload)
        listener = Deepsearch.configuration.listener
        unless listener.respond_to?(:on_deepsearch_event)
          Deepsearch.configuration.logger.debug("Attached listener does not respond to on_deepsearch_event, skipping notification")
          return
        end

        begin
          listener.on_deepsearch_event(event, **payload)
        rescue StandardError => e
          Deepsearch.configuration.logger.debug("Deepsearch listener failed: #{e.message}")
        end
      end

      def with_retry(&block)
        retries = 0
        begin
          result = block.call
          # Handle "soft" failures from steps that return a result object with a #failure? method
          raise "Operation failed: #{result.error}" if result.respond_to?(:failure?) && result.failure?

          result
        rescue StandardError => e
          raise e unless (retries += 1) <= 1

          Deepsearch.configuration.logger.debug("Retrying after error: #{e.message}")
          retry
        end
      end
    end
  end
end

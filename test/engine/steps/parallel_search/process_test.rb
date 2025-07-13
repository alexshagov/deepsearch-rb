# frozen_string_literal: true

require_relative "../../../test_helper"
require "deepsearch/engine/steps/parallel_search/process"
require "deepsearch/engine/steps/parallel_search/search"

module Deepsearch
  class Engine
    module Steps
      module ParallelSearch
        class ProcessTest < Minitest::Test
          def setup
            @initial_query = "test query"
            @sub_queries = %w[sub1 sub2]
            @mock_adapter = Minitest::Mock.new
            @options = { max_results: 5 }

            @process = Process.new(
              initial_query: @initial_query,
              sub_queries: @sub_queries,
              search_adapter: @mock_adapter,
              **@options
            )
          end

          def test_execute_returns_successful_result_with_websites
            # Arrange
            mock_search = Minitest::Mock.new
            expected_websites = [{ 'url' => 'http://example.com' }]
            mock_search.expect :output, expected_websites

            Search.stub :new, ->(*_) { mock_search } do
              # Act
              result = @process.execute

              # Assert
              assert result.success?
              assert_equal expected_websites, result.websites
            end
            mock_search.verify
          end

          def test_execute_handles_no_results
            # Arrange
            mock_search = Minitest::Mock.new
            mock_search.expect :output, []

            Search.stub :new, ->(*_) { mock_search } do
              # Act
              result = @process.execute

              # Assert
              assert result.success?
              assert_empty result.websites
            end
            mock_search.verify
          end

          def test_execute_handles_errors
            # Arrange
            Search.stub :new, ->(*) { raise StandardError, "Search failed" } do
              # Act
              result = @process.execute

              # Assert
              refute result.success?
              assert_empty result.websites
              assert_equal "Search failed", result.error
            end
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

require_relative '../test_helper'
require 'deepsearch/engine/pipeline'

module Deepsearch
  class Engine
    class MockedPipelineTest < Minitest::Test
      def setup
        @query = 'what is ruby on rails?'
        @pipeline = Pipeline.new(Deepsearch::SearchAdapters.create(:mock))

        # Create mock objects (behavior verification) to be used across tests.
        @prepare_subqueries_mock = Minitest::Mock.new
        @parallel_search_mock = Minitest::Mock.new
        @data_aggregation_mock = Minitest::Mock.new
        @rag_mock = Minitest::Mock.new
        @summarization_mock = Minitest::Mock.new
      end

      def test_execute_pipeline_with_mocks
        # Arrange
        # 1a. Build stub result objects for each step.
        prepare_subqueries_result = build_prepare_subqueries_result
        parallel_search_result = build_parallel_search_result
        data_aggregation_result = build_data_aggregation_result
        final_summary_result = build_summarization_result

        # 1b. Stub LLM calls required to build the RAG result object.
        mock_embedding_result = Minitest::Mock.new
        mock_embedding_result.expect :vectors, [0.1, 0.2, 0.3]
        mock_llm_chat = Minitest::Mock.new
        enrichment_response = OpenStruct.new(content: 'ruby on rails, web framework, mvc')
        mock_llm_chat.expect :ask, enrichment_response, [String]

        rag_result = nil
        RubyLLM.stub :chat, mock_llm_chat do
          RubyLLM.stub(:embed, mock_embedding_result) do
            rag_result = build_rag_result(prepare_subqueries_result.cleaned_query)
          end
        end

        # 1c. Set mock expectations for each pipeline step process.
        @prepare_subqueries_mock.expect :execute, prepare_subqueries_result
        @parallel_search_mock.expect :execute, parallel_search_result
        @data_aggregation_mock.expect :execute, data_aggregation_result
        @rag_mock.expect :execute, rag_result
        @summarization_mock.expect :execute, final_summary_result

        # Act
        final_result = nil
        with_pipeline_stubs do
          final_result = @pipeline.execute(@query)
        end

        # Assert
        assert_instance_of Steps::Summarization::Result, final_result
        assert final_result.success?
        assert_nil final_result.error
        assert_equal 'This is the final summary.', final_result.summary

        # Assert: verify all mocks were called as expected.
        verify_mocks
        mock_llm_chat.verify
        mock_embedding_result.verify
      end

      def test_execute_pipeline_handles_preprocessing_failure
        # Arrange: Mock PrepareSubqueries::Process to return a failure result
        mock_prepare_subqueries_result = Steps::PrepareSubqueries::Result.new(
          cleaned_query: '',
          sub_queries: [],
          original_query: @query,
          error: 'LLM not available'
        )
        mock_prepare_subqueries_process = Minitest::Mock.new
        # Expect two calls because of retry logic
        2.times do
          mock_prepare_subqueries_process.expect :execute, mock_prepare_subqueries_result
        end
        # Act & Assert
        Steps::PrepareSubqueries::Process.stub :new, ->(_query) { mock_prepare_subqueries_process } do
          exception = assert_raises(RuntimeError) { @pipeline.execute(@query) }
          assert_equal 'Operation failed: LLM not available', exception.message
        end
        mock_prepare_subqueries_process.verify
      end

      private

      def with_pipeline_stubs(&block)
        Steps::PrepareSubqueries::Process.stub :new, ->(*) { @prepare_subqueries_mock } do
          Steps::ParallelSearch::Process.stub :new, ->(*) { @parallel_search_mock } do
            Steps::DataAggregation::Process.stub :new, ->(*) { @data_aggregation_mock } do
              Steps::Rag::Process.stub :new, ->(*) { @rag_mock } do
                Steps::Summarization::Process.stub :new, ->(*) { @summarization_mock }, &block
              end
            end
          end
        end
      end

      def verify_mocks
        @prepare_subqueries_mock.verify
        @parallel_search_mock.verify
        @data_aggregation_mock.verify
        @rag_mock.verify
        @summarization_mock.verify
      end

      # --- Result Builder Helpers ---

      def build_prepare_subqueries_result
        Steps::PrepareSubqueries::Result.new(
          cleaned_query: 'what is ruby on rails',
          sub_queries: ['ruby on rails overview', 'rails getting started'],
          original_query: @query, error: nil
        )
      end

      def build_parallel_search_result
        Steps::ParallelSearch::Result.new(websites: [{ 'url' => 'https://rubyonrails.org' }])
      end

      def build_data_aggregation_result
        parsed_website = Steps::DataAggregation::ParsedWebsite.allocate.tap do |p|
          p.instance_variable_set(:@url, 'https://rubyonrails.org')
          p.instance_variable_set(:@success, true)
          p.instance_variable_set(:@content, 'Ruby on Rails is a web framework.')
        end
        Steps::DataAggregation::Result.new(parsed_websites: [parsed_website])
      end

      def build_rag_result(cleaned_query)
        query_obj = Steps::Rag::Values::Query.new(text: cleaned_query)
        chunk = Steps::Rag::Values::Chunk.new(text: 'chunk of text', document_url: 'https://rubyonrails.org')
        Steps::Rag::Values::Result.new(query: query_obj, relevant_chunks: [chunk])
      end

      def build_summarization_result
        Steps::Summarization::Result.new(summary: 'This is the final summary.', error: nil)
      end
    end
  end
end

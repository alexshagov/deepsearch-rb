# frozen_string_literal: true

require_relative "test_helper"
require "deepsearch"
require "ostruct"

# Integration test for the full Deepsearch pipeline.
# External dependencies are mocked to ensure the test runs without network access.
# - RubyLLM (subquery generation, embeddings, summarization).
# - Net::HTTP to prevent live web page fetching.
class DeepsearchIntegrationTest < Minitest::Test
  def setup
    @query = "what is ruby on rails?"
  end

  def teardown
    Deepsearch.reset_configuration!
  end

  def test_full_search_pipeline
    # Arrange
    # 1. Mock listener for events
    mock_listener = Minitest::Mock.new
    steps = %i[prepare_subqueries parallel_search data_aggregation rag summarization]
    steps.each do |step_name|
      mock_listener.expect(
        :on_deepsearch_event, nil, [:step_completed],
        step: step_name,
        result: ->(r) { r.respond_to?(:success?) }
      )
    end
    Deepsearch.configure { |c| c.listener = mock_listener }

    # 2. Mock LLM chat for subqueries, enrichment, and summarization
    mock_llm_chat = Minitest::Mock.new
    subquery_response = OpenStruct.new(content: "rails ecosystem\nror vs sinatra")
    enrichment_response = OpenStruct.new(content: "web framework, mvc, active record")
    summary_response = OpenStruct.new(content: "Final summary about RoR. [1](https://rubyonrails.org)")
    mock_llm_chat.expect :ask, subquery_response, [String] # For subqueries
    mock_llm_chat.expect :ask, enrichment_response, [String] # For query enrichment
    mock_llm_chat.expect :ask, summary_response, [String] # For summary

    # 3. Mock LLM behavior for embeddings
    embed_stub = lambda do |texts|
      mock_embedding = Minitest::Mock.new
      if texts.is_a?(String) # For the main query in Rag::Values::Query
        mock_embedding.expect :vectors, [0.1, 0.2, 0.3]
      else # For document chunks in Rag::Process
        vectors = texts.map.with_index { |_, i| Array.new(3) { |j| (i + j + 1) * 0.1 } }
        mock_embedding.expect :vectors, vectors
      end
      mock_embedding
    end

    # 4. Mock Search Adapter to avoid live web searches
    adapter_search_results_initial = {
      "results" => [
        { "url" => "https://rubyonrails.org", "content" => "Ruby on Rails is a framework." },
        { "url" => "https://guides.rubyonrails.org", "content" => "Rails guides teach you." }
      ]
    }
    mock_search_adapter = Minitest::Mock.new
    mock_search_adapter.expect :search, adapter_search_results_initial, [@query, {}]
    2.times do
      # For subqueries, we accept any string other than the main query.
      mock_search_adapter.expect(:search, adapter_search_results_initial) { |q, o| q.is_a?(String) && q != @query && o == {} }
    end

    # 5. Mock Net::HTTP for data aggregation to avoid live page fetching
    mock_http_response1 = Minitest::Mock.new
    mock_http_response1.expect :is_a?, true, [Net::HTTPSuccess]
    mock_http_response1.expect :body, "<html><body>Mocked HTML for rubyonrails.org</body></html>"

    mock_http_response2 = Minitest::Mock.new
    mock_http_response2.expect :is_a?, true, [Net::HTTPSuccess]
    mock_http_response2.expect :body, "<html><body>Mocked HTML for guides.rubyonrails.org</body></html>"

    mock_http1 = Minitest::Mock.new
    mock_http1.expect :use_ssl=, true, [true]
    mock_http1.expect :read_timeout=, 10, [10]
    mock_http1.expect :open_timeout=, 5, [5]
    mock_http1.expect :request, mock_http_response1, [Net::HTTP::Get]

    mock_http2 = Minitest::Mock.new
    mock_http2.expect :use_ssl=, true, [true]
    mock_http2.expect :read_timeout=, 10, [10]
    mock_http2.expect :open_timeout=, 5, [5]
    mock_http2.expect :request, mock_http_response2, [Net::HTTP::Get]

    http_new_stub = lambda do |host, _port|
      case host
      when "rubyonrails.org" then mock_http1
      when "guides.rubyonrails.org" then mock_http2
      else raise "Unexpected host for Net::HTTP.new: #{host}"
      end
    end

    # Act
    result = nil
    RubyLLM.stub :chat, mock_llm_chat do
      RubyLLM.stub :embed, embed_stub do
        Deepsearch::SearchAdapters::TavilyAdapter.stub :new, ->(*) { mock_search_adapter } do
          Net::HTTP.stub :new, http_new_stub do
            result = Deepsearch.search(@query)
          end
        end
      end
    end

    # Assert
    mock_listener.verify
    mock_llm_chat.verify
    mock_search_adapter.verify
    mock_http1.verify
    mock_http_response1.verify
    mock_http2.verify
    mock_http_response2.verify


    assert result.success?
    assert_equal "Final summary about RoR. [1](https://rubyonrails.org)", result.summary
  end
end
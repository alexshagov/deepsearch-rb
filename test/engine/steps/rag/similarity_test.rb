# frozen_string_literal: true

require_relative "../../../test_helper"
require "deepsearch/engine/steps/rag/similarity"
require "deepsearch/engine/steps/rag/values/query"
require "deepsearch/engine/steps/rag/values/chunk"

module Deepsearch
  class Engine
    module Steps
      module Rag
        class SimilarityTest < Minitest::Test
          def setup
            @similarity = Similarity.new
            @query_text = "test query"

            mock_llm_chat = Minitest::Mock.new
            enrichment_response = OpenStruct.new(content: "test,query,tags")
            mock_llm_chat.expect :ask, enrichment_response, [String]

            # Mock RubyLLM.embed behavior for Query object creation
            mock_embedding_result = Minitest::Mock.new
            mock_embedding_result.expect :vectors, [1.0, 0.0, 0.0]
            RubyLLM.stub :chat, mock_llm_chat do
              RubyLLM.stub :embed, mock_embedding_result do
                @query = Values::Query.new(text: @query_text)
              end
            end

            @chunk1 = Values::Chunk.new(text: "perfect match", document_url: "url1")
            @chunk1.embedding = [1.0, 0.0, 0.0] # score 1.0

            @chunk2 = Values::Chunk.new(text: "very close match", document_url: "url2")
            @chunk2.embedding = [0.95, 0.1, 0.0] # score ~0.99

            @chunk3 = Values::Chunk.new(text: "close match", document_url: "url3")
            @chunk3.embedding = [0.9, 0.3, 0.1] # score ~0.94

            @chunk4 = Values::Chunk.new(text: "somewhat relevant", document_url: "url4")
            @chunk4.embedding = [0.8, 0.5, 0.3] # score ~0.8

            @chunk5 = Values::Chunk.new(text: "irrelevant", document_url: "url5")
            @chunk5.embedding = [0.0, 1.0, 0.0] # score 0.0

            @all_chunks = [@chunk1, @chunk2, @chunk3, @chunk4, @chunk5]
          end

          def teardown
            Deepsearch.reset_configuration!
          end          

          def test_cosine_similarity
            # Arrange
            vec_a = [1, 2, 3]
            vec_b = [4, 5, 6]
            expected = 32 / (Math.sqrt(14) * Math.sqrt(77))

            # Act & Assert
            assert_in_delta expected, @similarity.send(:cosine_similarity, vec_a, vec_b)
          end

          def test_find_relevant_chunks
            # Arrange (in setup)

            # Act
            relevant_chunks = @similarity.find_relevant(@query, @all_chunks)

            # Assert
            assert_equal 3, relevant_chunks.size
            assert_includes relevant_chunks, @chunk1
            assert_includes relevant_chunks, @chunk2
            assert_includes relevant_chunks, @chunk3
            refute_includes relevant_chunks, @chunk4
            refute_includes relevant_chunks, @chunk5
          end

          def test_find_relevant_chunks_with_different_threshold
            # Arrange (in setup)

            # Act
            relevant_chunks = @similarity.find_relevant(@query, @all_chunks, threshold: 0.95)

            # Assert
            # Best score is 1.0. Cutoff is 0.95, so chunk3 (~0.94) is excluded.
            assert_equal 2, relevant_chunks.size
            assert_includes relevant_chunks, @chunk1
            assert_includes relevant_chunks, @chunk2
          end

          def test_find_relevant_with_empty_chunks
            # Arrange (in setup)

            # Act & Assert
            assert_equal [], @similarity.find_relevant(@query, [])
          end
        end
      end
    end
  end
end
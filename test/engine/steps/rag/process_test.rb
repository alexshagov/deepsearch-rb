# frozen_string_literal: true

require_relative '../../../test_helper'
require 'deepsearch/engine/steps/rag/process'
require 'ostruct'

module Deepsearch
  class Engine
    module Steps
      module Rag
        class ProcessTest < Minitest::Test
          def setup
            @mock_query = Minitest::Mock.new # This will be our fake query object
            @mock_query.expect :text, 'test query'
            @parsed_websites = [
              OpenStruct.new(url: 'url1', content: 'some content here'),
              OpenStruct.new(url: 'url2', content: 'more content here')
            ]
            # Stub Query.new to avoid the real LLM call during setup
            Values::Query.stub :new, ->(text:) { @mock_query } do
              @process = Process.new(query: 'test query', parsed_websites: @parsed_websites)
            end
          end

          def test_execute_orchestrates_chunking_embedding_and_similarity_search
            # Arrange
            mock_chunker = Minitest::Mock.new
            mock_similarity = Minitest::Mock.new
            mock_embedding = Minitest::Mock.new

            chunk1 = Values::Chunk.new(text: 'some content')
            chunk2 = Values::Chunk.new(text: 'here')
            chunk3 = Values::Chunk.new(text: 'more content')
            all_chunks = [chunk1, chunk2, chunk3]

            mock_chunker.expect :chunk, [chunk1, chunk2], ['some content here']
            mock_chunker.expect :chunk, [chunk3], ['more content here']

            texts_to_embed = all_chunks.map(&:text)
            mock_embedding.expect :vectors, [[1.0], [2.0], [3.0]]

            mock_similarity.expect :find_relevant, [chunk1, chunk3], [@mock_query, all_chunks]

            Chunker.stub :new, mock_chunker do
              RubyLLM.stub :embed, lambda { |texts|
                assert_equal texts_to_embed, texts
                mock_embedding
              } do
                Similarity.stub :new, mock_similarity do
                  # Act
                  result = @process.execute

                  # Assert
                  assert result.success?
                  assert_equal [chunk1, chunk3], result.relevant_chunks
                  assert_equal 'url1', chunk1.document_url
                  assert_equal 'url1', chunk2.document_url
                  assert_equal 'url2', chunk3.document_url
                  # Assert that embeddings were assigned correctly
                  assert_equal [1.0], chunk1.embedding
                  assert_equal [2.0], chunk2.embedding
                  assert_equal [3.0], chunk3.embedding
                end
              end
            end

            # Assert: verify mock expectations
            mock_chunker.verify
            mock_similarity.verify
            mock_embedding.verify
          end

          def test_execute_limits_chunks_per_website
            # Arrange

            long_content = 'This content is long and will be chunked many times.'
            short_content = 'Short content.'
            parsed_websites = [
              OpenStruct.new(url: 'http://long.com', content: long_content),
              OpenStruct.new(url: 'http://short.com', content: short_content)
            ]
            Values::Query.stub :new, ->(text:) { @mock_query } do
              @process = Process.new(query: 'test query', parsed_websites: parsed_websites)
            end

            mock_chunker = Minitest::Mock.new
            long_chunks = Array.new(20) { Values::Chunk.new(text: 'long chunk') }
            short_chunks = Array.new(5) { Values::Chunk.new(text: 'short chunk') }
            mock_chunker.expect(:chunk, long_chunks, [long_content])
            mock_chunker.expect(:chunk, short_chunks, [short_content])

            # After limiting, there should be 15 chunks from long.com and 5 from short.com. Total 20.
            expected_chunk_count_for_embedding = 15 + 5

            mock_embedding = Minitest::Mock.new
            mock_embedding.expect(:vectors, Array.new(expected_chunk_count_for_embedding) { [0.1] })

            mock_similarity = Minitest::Mock.new
            mock_similarity.expect(:find_relevant, [], [@mock_query, lambda { |chunks|
              chunks.size == expected_chunk_count_for_embedding
            }])

            Chunker.stub :new, mock_chunker do
              RubyLLM.stub(:embed, lambda { |texts|
                assert_equal expected_chunk_count_for_embedding, texts.size
                mock_embedding
              }) do
                Similarity.stub :new, mock_similarity do
                  # Act
                  @process.execute
                end
              end
            end

            # Assert
            mock_chunker.verify
            mock_embedding.verify
            mock_similarity.verify
          end

          def test_execute_returns_error_result_on_failure
            # Arrange
            Chunker.stub :new, -> { raise StandardError, 'Chunking failed' } do
              # Act
              result = @process.execute

              # Assert
              refute result.success?
              assert_empty result.relevant_chunks
              assert_equal 'Chunking failed', result.error
            end
          end
        end
      end
    end
  end
end

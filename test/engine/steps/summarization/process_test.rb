# frozen_string_literal: true

require_relative "../../../test_helper"
require "deepsearch/engine/steps/summarization/process"
require "deepsearch/engine/steps/rag/values/chunk"
require "ostruct"

module Deepsearch
  class Engine
    module Steps
      module Summarization
        class ProcessTest < Minitest::Test
          def setup
            query_text = "What is Ruby?"
            @mock_query = OpenStruct.new(text: query_text)

            @relevant_chunks = [
              ::Deepsearch::Engine::Steps::Rag::Values::Chunk.new(
                text: "Ruby is a dynamic language.",
                document_url: "http://example.com/ruby"
              ),
              ::Deepsearch::Engine::Steps::Rag::Values::Chunk.new(
                text: "It was created by Matz.",
                document_url: "http://example.com/matz"
              )
            ]

            @process = Process.new(query: @mock_query, relevant_chunks: @relevant_chunks)
          end

          def test_execute_generates_summary_successfully
            # Arrange
            mock_chat = Minitest::Mock.new
            summary_response = OpenStruct.new(content: "Ruby is a dynamic language created by Matz.")
            mock_chat.expect :ask, summary_response, [String]

            RubyLLM.stub :chat, mock_chat do
              # Act
              result = @process.execute

              # Assert
              assert result.success?
              assert_equal "Ruby is a dynamic language created by Matz.", result.summary
            end
            mock_chat.verify
          end

          def test_prompt_is_built_correctly
            # Arrange (in setup)

            # Act
            prompt = @process.send(:build_summary_prompt)

            # Assert
            assert_match(/User Query: "What is Ruby\?"/, prompt)
            assert_match(/Source \[1\]:\nRuby is a dynamic language./, prompt)
            assert_match(/Source \[2\]:\nIt was created by Matz./, prompt)
            assert_match(/\[1\]: http:\/\/example.com\/ruby/, prompt)
            assert_match(/\[2\]: http:\/\/example.com\/matz/, prompt)
          end

          def test_execute_handles_no_relevant_chunks
            # Arrange
            process = Process.new(query: @mock_query, relevant_chunks: [])

            RubyLLM.stub :chat, ->(*) { flunk "LLM should not be called when there are no chunks" } do
              # Act
              result = process.execute

              # Assert
              assert result.success?
              assert_equal "No relevant content found to summarize.", result.summary
            end
          end

          def test_execute_handles_llm_error
            # Arrange
            RubyLLM.stub :chat, -> { raise StandardError, "LLM failed" } do
              # Act
              result = @process.execute

              # Assert
              refute result.success?
              assert_nil result.summary
              assert_equal "LLM failed", result.error
            end
          end
        end
      end
    end
  end
end
# frozen_string_literal: true

require_relative '../../../test_helper'
require 'deepsearch/engine/steps/prepare_subqueries/process'
require 'ostruct'

module Deepsearch
  class Engine
    module Steps
      module PrepareSubqueries
        class ProcessTest < Minitest::Test
          def setup
            @original_query = '  What is ruby?  '
            @process = Process.new(@original_query)
          end

          def test_execute_with_successful_llm_call
            # Arrange
            mock_chat = Minitest::Mock.new
            llm_response = OpenStruct.new(content: "ruby language\n- ruby programming\n* what is ruby used for")
            mock_chat.expect :ask, llm_response, [String]

            RubyLLM.stub :chat, mock_chat do
              # Act
              result = @process.execute

              # Assert
              assert result.success?
              assert_nil result.error
              assert_equal 'What is ruby?', result.cleaned_query
              expected_subqueries = ['ruby language', 'ruby programming', 'what is ruby used for']
              assert_equal expected_subqueries, result.sub_queries
            end
            mock_chat.verify
          end

          def test_execute_handles_llm_error_gracefully
            # Arrange
            mock_chat = Minitest::Mock.new
            mock_chat.expect :ask, ->(*) { raise StandardError, 'LLM API down' }

            RubyLLM.stub :chat, mock_chat do
              # Act
              result = @process.execute

              # Assert
              assert result.success?
              assert_empty result.sub_queries
            end
          end

          def test_execute_fails_with_invalid_input
            # Arrange
            process = Process.new('   ')

            # Act
            result = process.execute

            # Assert
            refute result.success?
            assert_equal 'Original query is required for preprocessing', result.error
          end
        end
      end
    end
  end
end

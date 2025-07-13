# frozen_string_literal: true

module Deepsearch
  class Engine
    module Steps
      module PrepareSubqueries
        # Represents the result of the sub-query preparation step.
        # It holds the cleaned original query, the generated sub-queries, and any potential error.
        class Result
          attr_reader :cleaned_query, :sub_queries, :original_query, :error

          def initialize(cleaned_query:, sub_queries:, original_query:, error: nil)
            @cleaned_query = cleaned_query
            @sub_queries = sub_queries
            @original_query = original_query
            @error = error
          end

          def success?
            error.nil?
          end

          def failure?
            !success?
          end
        end
      end
    end
  end
end

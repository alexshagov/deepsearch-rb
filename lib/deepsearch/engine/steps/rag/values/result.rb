# frozen_string_literal: true

module Deepsearch
  class Engine
    module Steps
      module Rag
        module Values
          # Represents the result of the RAG processing step.
          # It contains the original query object and a list of text chunks
          # deemed most relevant to the query.
          class Result
            attr_reader :query, :relevant_chunks, :error, :success

            def initialize(query: nil, relevant_chunks: [], error: nil)
              @query = query
              @relevant_chunks = relevant_chunks
              @success = error.nil?
              @error = error
            end

            def success?
              @success
            end

            def failure?
              !success?
            end
          end
        end
      end
    end
  end
end

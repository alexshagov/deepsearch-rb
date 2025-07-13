# frozen_string_literal: true

module Deepsearch
  class Engine
    module Steps
      module Summarization
        # Represents the result of the summarization step.
        # It holds the final, synthesized summary and any potential error message.
        class Result
          attr_reader :summary, :error, :success

          def initialize(summary: nil, error: nil)
            @summary = summary
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
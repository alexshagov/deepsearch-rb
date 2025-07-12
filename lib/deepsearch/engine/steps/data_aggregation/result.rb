# frozen_string_literal: true

module Deepsearch
  class Engine
    module Steps
      module DataAggregation
        # Represents the result of the data aggregation step.
        # It holds the collection of successfully parsed websites and any potential error message.
        class Result
          attr_reader :parsed_websites, :error

          def initialize(parsed_websites: [], error: nil)
            @parsed_websites = parsed_websites
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
# frozen_string_literal: true

module Deepsearch
  class Engine
    module Steps
      module ParallelSearch
        # Represents the result of the parallel search step.
        # It holds the aggregated list of websites found and any potential error message.
        class Result
          attr_reader :query, :websites, :error, :search_duration

          def initialize(websites: [], error: nil)
            @websites = websites || []
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
# frozen_string_literal: true

require "async"
require "async/semaphore"
require_relative "parsed_website"
require_relative "result"

module Deepsearch
  class Engine
    module Steps
      module DataAggregation
        # Takes a list of website URLs from a previous search step and processes them in parallel.
        # For each URL, it fetches, parses, and cleans the content using `ParsedWebsite`.
        # It aggregates the successfully parsed websites into a `Result` object.
        class Process
          MAX_CONCURRENCY = 30

          attr_reader :websites

          def initialize(websites: [])
            @websites = websites
          end

          def execute
            Deepsearch.configuration.logger.debug("Starting data aggregation for #{@websites.size} websites")

            parsed_websites = process_in_parallel
            parsed_websites.filter!(&:success?)

            Result.new(
              parsed_websites: parsed_websites
            )
          rescue StandardError => e
            Result.new(
              parsed_websites: [],
              error: e.message
            )
          end

          private

          def process_in_parallel
            Sync do |task|
              semaphore = Async::Semaphore.new(MAX_CONCURRENCY, parent: task)
              websites.map do |website|
                semaphore.async do
                  ParsedWebsite.new(url: website['url'])
                end
              end.map(&:wait)
            end
          end
        end
      end
    end
  end
end

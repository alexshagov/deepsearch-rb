# frozen_string_literal: true

require_relative 'result'

module Deepsearch
  class Engine
    module Steps
      module PrepareSubqueries
        class Process
          def initialize(original_query)
            @original_query = original_query
          end

          def execute
            validate_input
            process_query
          rescue StandardError => e
            PrepareSubqueries::Result.new(
              cleaned_query: '',
              sub_queries: [],
              original_query: @original_query.to_s,
              error: e.message
            )
          end

          private

          def validate_input
            return if @original_query && !@original_query.strip.empty?

            raise StandardError, 'Original query is required for preprocessing'
          end

          def process_query
            cleaned_query = clean_query(@original_query)
            subqueries = generate_subqueries(cleaned_query)

            PrepareSubqueries::Result.new(
              cleaned_query: cleaned_query,
              original_query: @original_query,
              sub_queries: subqueries
            )
          end

          def clean_query(query)
            query.strip.gsub(/\s+/, ' ')
          end

          def generate_subqueries(query)
            Deepsearch.configuration.logger.debug('Attempting to generate subqueries using LLM...')
            chat = RubyLLM.chat

            prompt = Deepsearch.configuration.prompts.subquery_prompt(query: query)
            Deepsearch.configuration.logger.debug('Sending prompt to LLM...')
            response = chat.ask(prompt)

            Deepsearch.configuration.logger.debug('Received response from LLM')
            subqueries = parse_subqueries(response.content)
            Deepsearch.configuration.logger.debug("Generated #{subqueries.size} subqueries")
            subqueries
          rescue StandardError => e
            Deepsearch.configuration.logger.debug("Error generating subqueries: #{e.message}")
            Deepsearch.configuration.logger.debug("Error class: #{e.class}")
            Deepsearch.configuration.logger.debug("Backtrace: #{e.backtrace.first(3).join('\n')}")
            []
          end

          def parse_subqueries(response_content)
            return [] unless response_content

            response_content.split("\n")
                            .map(&:strip)
                            .reject(&:empty?)
                            .map { |line| line.gsub(/^\d+\.\s*|^[-*]\s*/, '') }
                            .map { |query| query.gsub(/^["']|["']$/, '') }
                            .reject(&:empty?)
                            .first(5)
          end
        end
      end
    end
  end
end

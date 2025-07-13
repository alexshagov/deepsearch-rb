# frozen_string_literal: true

require_relative 'result'

module Deepsearch
  class Engine
    module Steps
      module Summarization
        # Generates a final, synthesized answer to the user's query based on relevant text chunks.
        # It constructs a detailed prompt for an LLM, including the query, context from chunks,
        # and instructions for citing sources, then returns the LLM's response.
        class Process
          attr_reader :query, :relevant_chunks

          def initialize(query:, relevant_chunks:)
            @query = query
            @relevant_chunks = relevant_chunks
          end

          def execute
            return Result.new(summary: "No relevant content found to summarize.") if relevant_chunks.empty?

            prompt = build_summary_prompt
            Deepsearch.configuration.logger.debug("Summarizing content with LLM...")
            response = RubyLLM.chat.ask(prompt)
            Deepsearch.configuration.logger.debug("Summarization complete.")

            Result.new(summary: response.content)
          rescue StandardError => e
            Deepsearch.configuration.logger.debug("Error during summarization: #{e.message}")
            Result.new(summary: nil, error: e.message)
          end

          private

          def build_summary_prompt
            chunks_by_url = relevant_chunks.group_by(&:document_url)
            citation_map = chunks_by_url.keys.each_with_index.to_h { |url, i| [url, i + 1] }
 
            context_text = chunks_by_url.map do |url, chunks|
              citation_number = citation_map[url]
              chunk_contents = chunks.map(&:text).join("\n\n")
              "Source [#{citation_number}]:\n#{chunk_contents}"
            end.join("\n\n---\n\n")
 
            sources_list = citation_map.map { |url, number| "[#{number}]: #{url}" }.join("\n")
            Deepsearch.configuration.prompts.summarization_prompt(query: @query.text, context_text: context_text, sources_list: sources_list)
          end
        end
      end
    end
  end
end          
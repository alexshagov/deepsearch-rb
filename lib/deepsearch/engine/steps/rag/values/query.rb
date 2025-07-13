# frozen_string_literal: true

module Deepsearch
  class Engine
    module Steps
      module Rag
        module Values
          # Represents a user query that has been prepared for the RAG process.
          # It enriches the original query text with LLM-generated tags to improve
          # embedding quality and then computes the embedding vector.
          class Query
            attr_reader :text, :embedding

            def initialize(text:)
              raise ArgumentError, 'Query text cannot be blank' if text.to_s.strip.empty?

              @text = text
              enriched_text = enrich_query_with_tags(text)
              @embedding = RubyLLM.embed(enriched_text).vectors
            end

            private

            def enrich_query_with_tags(original_text)
              prompt = Deepsearch.configuration.prompts.enrich_query_prompt(query: original_text)

              Deepsearch.configuration.logger.debug('Enriching query with LLM-generated tags...')
              response = RubyLLM.chat.ask(prompt)
              tags_list = response.content.strip
              Deepsearch.configuration.logger.debug("Generated tags for query enrichment: #{tags_list}")

              enriched_text = "#{original_text} - related concepts: #{tags_list}"
              Deepsearch.configuration.logger.debug("Enriched query for embedding: \"#{enriched_text}\"")
              enriched_text
            rescue StandardError => e
              Deepsearch.configuration.logger.debug("Failed to enrich query due to '#{e.message}'. Using original query for embedding.")
              original_text
            end
          end
        end
      end
    end
  end
end

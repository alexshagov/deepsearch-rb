# frozen_string_literal: true

require_relative 'values/chunk'
require_relative 'values/query'
require_relative 'values/result'
require_relative 'chunker'
require_relative 'similarity'

module Deepsearch
  class Engine
    module Steps
      module Rag
        # Implements the core Retrieval-Augmented Generation (RAG) logic.
        # It takes a query and a set of parsed websites, then:
        # 1. Chunks the website content into smaller pieces.
        # 2. Generates embeddings for all text chunks in batches.
        # 3. Uses a similarity search to find the chunks most relevant to the query.
        # 4. Returns a result containing the relevant chunks.
        class Process
          CHUNK_BATCH_SIZE = 100
          MAX_TOTAL_CHUNKS = 500
          MAX_CHUNKS_PER_WEBSITE = 15

          def initialize(query:, parsed_websites:)
            @query = Values::Query.new(text: query)
            @documents = parsed_websites.map do |website|
              { url: website.url, content: website.content }
            end
          end

          def execute
            chunker = Chunker.new
            all_chunks = @documents.each_with_object([]) do |doc, chunks|
              next if doc[:content].to_s.strip.empty?

              doc_chunks = chunker.chunk(doc[:content])
              if doc_chunks.count > MAX_CHUNKS_PER_WEBSITE
                Deepsearch.configuration.logger.debug("Truncating chunks for #{doc[:url]} from #{doc_chunks.count} to #{MAX_CHUNKS_PER_WEBSITE}")
                doc_chunks = doc_chunks.first(MAX_CHUNKS_PER_WEBSITE)
              end
              doc_chunks.each { |chunk| chunk.document_url = doc[:url] }
              chunks.concat(doc_chunks)
            end

            Deepsearch.configuration.logger.debug("Chunked #{@documents.count} documents into #{all_chunks.count} chunks")

            if all_chunks.count > MAX_TOTAL_CHUNKS
              Deepsearch.configuration.logger.debug("Chunk count (#{all_chunks.count}) exceeds limit of #{MAX_TOTAL_CHUNKS}. Truncating.")
              all_chunks = all_chunks.first(MAX_TOTAL_CHUNKS)
            end

            all_chunks.each_slice(CHUNK_BATCH_SIZE) do |batch|
              texts = batch.map(&:text)
              embeddings = RubyLLM.embed(texts).vectors
              batch.each_with_index { |chunk, i| chunk.embedding = embeddings[i] }
            end

            Deepsearch.configuration.logger.debug("Generated embeddings for #{all_chunks.count} chunks, initiating similarity match..")
            relevant_chunks = Similarity.new.find_relevant(@query, all_chunks)
            Deepsearch.configuration.logger.debug("Found #{relevant_chunks.count} relevant chunks for query: '#{@query.text}'")

            Values::Result.new(
              query: @query,
              relevant_chunks: relevant_chunks
            )
          rescue StandardError => e
            Values::Result.new(
              query: @query,
              relevant_chunks: [],
              error: e.message
            )
          end
        end
      end
    end
  end
end

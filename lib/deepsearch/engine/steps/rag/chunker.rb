# frozen_string_literal: true

module Deepsearch
  class Engine
    module Steps
      module Rag
        # Splits a large piece of text content into smaller, overlapping chunks.
        # This is a prerequisite for generating embeddings and performing similarity searches in a RAG pipeline.
        class Chunker
          MAX_CHUNK_SIZE = 7500
          OVERLAP_SIZE = 300

          def chunk(content)
            return [Values::Chunk.new(text: content)] if content.length <= MAX_CHUNK_SIZE

            chunks = []
            step = MAX_CHUNK_SIZE - OVERLAP_SIZE

            i = 0
            while i < content.length
              chunk_text = content.slice(i, MAX_CHUNK_SIZE)
              chunks << Values::Chunk.new(text: chunk_text)
              i += step
            end
            chunks
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Deepsearch
  class Engine
    module Steps
      module Rag
        module Values
          # Represents a chunk of text from a document, along with its embedding and source URL.
          # This is the fundamental unit of data used in the RAG process.
          class Chunk
            attr_accessor :text, :embedding, :document_url
      
            def initialize(text:, embedding: nil, document_url: nil)
              @text = text
              @embedding = embedding
              @document_url = document_url
            end
          end
        end
      end
    end
  end
end
# frozen_string_literal: true

module Deepsearch
  class Engine
    module Steps
      module Rag
        # Calculates and filters text chunks based on their semantic similarity to a query.
        # It uses cosine similarity to score chunks against a query embedding and employs a two-step
        # filtering process: first, it retrieves a fixed number of top candidates (top-k), and
        # second, it filters these candidates based on a score relative to the best-scoring chunk.
        class Similarity
          TOP_K_CANDIDATES = 75
          RELATIVE_SCORE_THRESHOLD = 0.85

          def find_relevant(query, chunks, threshold: RELATIVE_SCORE_THRESHOLD)
            return [] if chunks.empty?

            similarities = calculate(chunks.map(&:embedding), query.embedding)

            top_candidates = top_k_with_scores(similarities, TOP_K_CANDIDATES)

            return [] if top_candidates.empty?

            best_score = top_candidates.first.first
            cutoff_score = best_score * threshold

            relevant_chunks = top_candidates.select { |score, _| score >= cutoff_score }
                                            .map { |_, index| chunks[index] }

            relevant_chunks
          end

          private

          def calculate(embeddings, query_embedding)
            embeddings.map { |embedding| cosine_similarity(embedding, query_embedding) }
          end

          def top_k_with_scores(similarities, k)
            similarities.each_with_index
                        .sort_by { |score, _| -score }
                        .first(k)
          end

          def cosine_similarity(vec_a, vec_b)
            return 0.0 unless vec_a.is_a?(Array) && vec_b.is_a?(Array)
            return 0.0 if vec_a.empty? || vec_b.empty?

            dot_product = vec_a.zip(vec_b).sum { |a, b| a * b }
            magnitude_a = Math.sqrt(vec_a.sum { |v| v**2 })
            magnitude_b = Math.sqrt(vec_b.sum { |v| v**2 })

            return 0.0 if magnitude_a.zero? || magnitude_b.zero?
            dot_product / (magnitude_a * magnitude_b)
          end
        end
      end
    end
  end
end
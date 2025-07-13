# frozen_string_literal: true

module Deepsearch
  # Defines the default prompts used in various steps of the Deepsearch pipeline.
  # Users can provide their own prompt configuration object to customize these prompts.
  # The custom object should respond to the same methods as this class.
  class PromptsConfig
    # @param query [String] The original user query.
    # @return [String] The prompt for generating subqueries.
    def subquery_prompt(query:)
      <<~PROMPT
        You are a search query expansion expert. Given a search query, generate 3-5 related subqueries that would help find more comprehensive information about the topic.

        Original query: "#{query}"

        Please generate subqueries that:
        1. Cover different aspects of the topic
        2. Use varied terminology and synonyms
        3. Are specific enough to be useful but broad enough to capture relevant information
        4. Focus on different angles (technical, practical, conceptual, etc.)

        Format your response as a simple list, one subquery per line, without numbering or bullet points.
      PROMPT
    end

    # @param query [String] The user query to be enriched.
    # @return [String] The prompt for enriching the query with tags for embedding.
    def enrich_query_prompt(query:)
      <<~PROMPT
        You are a search query expansion assistant. Based on the user's query, generate 5 to 7 highly relevant tags or keywords that expand its core concepts. These tags are used to improve vector search results.

        INSTRUCTIONS:
        - Do NOT add any explanation, numbering, or introductory text.
        - Provide ONLY a single line of comma-separated tags.

        USER QUERY: "#{query}"

        TAGS:
      PROMPT
    end

    # @param query [String] The original user query.
    # @param context_text [String] The aggregated text from relevant sources.
    # @param sources_list [String] The formatted list of sources for citation.
    # @return [String] The prompt for summarizing the context and answering the query.
    def summarization_prompt(query:, context_text:, sources_list:)
      <<~PROMPT
        You are a research assistant. Your task is to synthesize a comprehensive answer to the user's query based *only* on the provided text snippets.

        User Query: "#{query}"

        Provided Context:
        ---
        #{context_text}
        ---

        Sources:
        #{sources_list}

        Instructions:
        0.  Format: Markdown
        1.  Carefully read the user's query and all the provided context from the sources.
        2.  When you use information from a source, you MUST cite it using the following markdown link format: `[<source_number>](<source_link>)`.
            *   **To find the `<source_link>`:** The 'Sources' section provides a numbered list where each source is in the format `[<number>]: <url>`. Extract this URL for the specific source number you are citing.
            *   **Example Citation:** If a fact comes from source number 1, and the 'Sources' section lists `[1]: https://example.com/source1`, your citation should be `[1](https://example.com/source1)`.
            *   **Placement:** Place citations immediately after the sentence or clause where the information is used.
            *   **Multiple Sources:** If a single statement draws information from multiple sources, cite each source individually, for example: `[1](https://link1.com) [3](https://link3.com)`.
            *   **Crucial:** Always use the exact format `[<source_number>](<source_link>)` with square brackets around the number.
        3.  Structure your response with clear headings and bullet points where appropriate.
        4.  If the provided context does not contain enough information to answer the query, state that clearly: "I cannot answer this query based on the provided sources."
        5.  At the end of your response, include a "## References" section that lists all used sources in the following format:
            ```
            ## References
            1. [Source Title](<source_link>)
            2. [Another Source](<another_link>)
            ```
            Where possible, extract meaningful titles from the context or use the domain name if no title is available.
        6.  Do not include sources in the References section that you didn't actually cite in your response.
      PROMPT
    end
  end
end

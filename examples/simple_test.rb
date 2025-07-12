require_relative "../lib/deepsearch"

Deepsearch.configure do |config|
  # Using gemini
  config.ruby_llm.gemini_api_key = ENV['GEMINI_API_KEY']
  config.ruby_llm.default_model = 'gemini-2.0-flash-lite'
  config.ruby_llm.default_embedding_model = 'text-embedding-004'

  config.serper_api_key = ENV['SERPER_API_KEY']
  config.search_adapter = :serper
end

result = Deepsearch.search("Recent open source LLM news (may-july 2025)", max_total_search_results: 25)
puts "Search result:"
puts "=" * 50
puts result.summary

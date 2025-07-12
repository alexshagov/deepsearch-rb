require_relative "../lib/deepsearch"
require_relative "../lib/deepsearch/engine/pipeline"


# Configure Deepsearch
Deepsearch.configure do |config|
  config.ruby_llm.gemini_api_key = ENV['GEMINI_API_KEY']
  config.ruby_llm.deepseek_api_key = ENV['DEEPSEEK_API_KEY']
  config.ruby_llm.default_model = 'gemini-2.0-flash-lite'
  config.ruby_llm.default_embedding_model = 'text-embedding-004'

  config.serper_api_key = ENV['SERPER_API_KEY']
  config.tavily_api_key = ENV['TAVILY_API_KEY']
  config.search_adapter = :serper
end

# Test the Pipeline directly
puts "Testing Pipeline directly"
puts "=" * 50

result = Deepsearch.search("July 2025 recent open source LLM news (ycombinator forum)", max_total_search_results: 25)
puts "Search result:"
puts result.summary
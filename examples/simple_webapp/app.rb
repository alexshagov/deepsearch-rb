require 'sinatra'
require 'sinatra/reloader'
require 'json'
require 'thin'
require 'sinatra-websocket'
require 'uri'
require 'deepsearch'

configure :development do
  register Sinatra::Reloader
end

set :server, 'thin'
set :sockets, []

Deepsearch.configure do |config|
  config.search_adapter = :serper
  config.serper_api_key = ENV['SERPER_API_KEY']
  config.ruby_llm.gemini_api_key = ENV['GEMINI_API_KEY']
  config.ruby_llm.default_model = 'gemini-2.0-flash-lite'
  config.ruby_llm.default_embedding_model = 'text-embedding-004'
end

class WebSocketListener
  def initialize(ws)
    @ws = ws
  end

  def on_deepsearch_event(_event, **payload)
    return unless @ws
    
    step_result = payload[:result]
    message = { type: 'event', step: payload[:step].to_s }

    details = case payload[:step]
              when :prepare_subqueries
                count = step_result.sub_queries&.count || 0
                queries = step_result.sub_queries&.map { |q| "\"#{q}\"" }&.join(', ')
                "Generated #{count} sub-queries: [#{queries}]"
              when :parallel_search
                count = step_result.websites&.count || 0
                "Found #{count} unique URLs from search."
              when :data_aggregation
                count = step_result.parsed_websites&.count || 0
                "Successfully parsed content from #{count} websites."
              when :rag
                count = step_result.relevant_chunks&.count || 0
                "Found #{count} relevant text chunks for the query."
              when :summarization
                "Generating final summary..."
              end

    if payload[:step] == :summarization && step_result.success?
      message[:type] = 'final_result'
      message[:summary] = step_result.summary
      message[:details] = "Summary generation complete."
    else
      message[:details] = details
    end

    message[:error] = step_result.error if step_result.respond_to?(:failure?) && step_result.failure?

    @ws.send(message.to_json)
  rescue StandardError => e
    error_message = { type: 'error', message: "Error in listener: #{e.message}" }.to_json
    @ws.send(error_message)
  end
end

get '/ws' do
  if !request.websocket?
    status 400
    'WebSocket connection required'
  else
    request.websocket do |ws|
      ws.onopen do
        puts "WebSocket connection opened at #{Time.now}"
        settings.sockets << ws
      end

      ws.onmessage do |msg|
        puts "Received WebSocket message at #{Time.now}: #{msg}"
        
        Thread.new do
          begin
            data = JSON.parse(msg)
            query = data['query']
            puts "Parsed query: #{query}"

            if query.to_s.strip.empty?
              ws.send({ type: 'error', message: 'Query cannot be empty.' }.to_json)
            else
              listener = WebSocketListener.new(ws)
              Deepsearch.configuration.listener = listener
              
              puts "Starting Deepsearch for query: #{query}"
              Deepsearch.search(query, max_total_search_results: 15)
              puts "Deepsearch completed for query: #{query}"
            end
          rescue JSON::ParserError => e
            ws.send({ type: 'error', message: 'Invalid request from client.' }.to_json)
          rescue StandardError => e
            ws.send({ type: 'error', message: "An unexpected error occurred: #{e.message}" }.to_json)
          end
        end
      end

      ws.onclose do
        puts "WebSocket connection closed at #{Time.now}"
        settings.sockets.delete(ws)
      end
    end
  end
end

get '/' do
  erb :index
end
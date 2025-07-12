# frozen_string_literal: true

require_relative "prompts_config"

module Deepsearch
  # Encapsulates configuration options for the underlying `ruby_llm` gem.
  # This provides a clean namespace for LLM settings within Deepsearch's configuration.
  #
  # @example
  #   Deepsearch.configure do |config|
  #     # Configure LLM settings via the `ruby_llm` accessor
  #     config.ruby_llm.openai_api_key = "sk-..."
  #     config.ruby_llm.default_model = "gpt-4o-mini"
  #     config.ruby_llm.request_timeout = 90
  #   end
  class RubyLLMConfig
    SUPPORTED_ATTRIBUTES = %i[
      openai_api_key openai_organization_id openai_project_id
      anthropic_api_key gemini_api_key deepseek_api_key openrouter_api_key
      ollama_api_base bedrock_api_key bedrock_secret_key bedrock_region
      bedrock_session_token openai_api_base default_model
      default_embedding_model default_image_model request_timeout max_retries
      retry_interval retry_backoff_factor retry_interval_randomness
      http_proxy logger log_file log_level log_assume_model_exists
    ].freeze

    attr_accessor(*SUPPORTED_ATTRIBUTES)

    def initialize
      # Set some sensible defaults for Deepsearch's use case
      @default_model = "gpt-4o-mini"
      @default_embedding_model = "text-embedding-3-small"
      @request_timeout = 30 # seconds
      @log_assume_model_exists = false
    end
  end

  # Configuration class for managing gem settings
  class Configuration
    # @!attribute listener
    #   An object that can listen to events from the Deepsearch pipeline.
    #   The object must respond to `on_deepsearch_event(event_name, **payload)`.
    #   @example
    #     class MyListener
    #       def on_deepsearch_event(event, step:, result:)
    #         puts "Event: #{event}, Step: #{step}, Success: #{result.success?}"
    #       end
    #     end
    #     Deepsearch.configure { |c| c.listener = MyListener.new
    attr_accessor :tavily_api_key, :serper_api_key, :search_adapter, :custom_search_adapter_class, :logger, :listener, :prompts
    attr_reader :ruby_llm

    def initialize
      @tavily_api_key = nil
      @serper_api_key = nil
      @search_adapter = :tavily
      @custom_search_adapter_class = nil
      @listener = nil
      @logger = Logger.new($stdout, level: Logger::DEBUG)
      @ruby_llm = RubyLLMConfig.new
      @prompts = PromptsConfig.new
    end

    # Reset configuration to default values
    def reset!
      @tavily_api_key = nil
      @serper_api_key = nil
      @search_adapter = :tavily
      @listener = nil
      @logger = Logger.new($stdout, level: Logger::DEBUG)
      @ruby_llm = RubyLLMConfig.new
      @prompts = PromptsConfig.new
    end

    # Configure RubyLLM with current settings from the `ruby_llm` config object.
    def configure_llm!
      require "ruby_llm"

      RubyLLM.configure do |config|
        RubyLLMConfig::SUPPORTED_ATTRIBUTES.each do |attr|
          value = @ruby_llm.public_send(attr)
          # Only set the value if it's not nil to avoid overriding RubyLLM's internal defaults.
          config.public_send("#{attr}=", value) unless value.nil?
        end
      end
    end
  end
end

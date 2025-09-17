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
  #
  class RubyLLMConfig
    def self.supported_attributes
      @supported_attributes ||= discover_attributes
    end

    def self.reset_supported_attributes!
      @supported_attributes = nil
    end

    private

    def self.discover_attributes
      if defined?(RubyLLM::Configuration)
        config_instance = RubyLLM::Configuration.new
      else
        require "ruby_llm"
        config_instance = RubyLLM::Configuration.new
      end
      
      # Getting all setter methods (ending with =) and remove the = suffix
      config_instance.public_methods(false)
        .select { |method| method.to_s.end_with?('=') }
        .map { |method| method.to_s.chomp('=').to_sym }
        .reject { |attr| [:configuration].include?(attr) }
    end

    public

    attr_accessor(*supported_attributes)

    def initialize
      @default_model = "gpt-4o-mini"
      @default_embedding_model = "text-embedding-3-small"
      @request_timeout = 30 # seconds
      @log_assume_model_exists = false
    end
  end

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
    attr_accessor :tavily_api_key, :serper_api_key, :search_adapter, :custom_search_adapter_class, :logger, :listener,
                  :prompts
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

    def reset!
      @tavily_api_key = nil
      @serper_api_key = nil
      @search_adapter = :tavily
      @listener = nil
      @logger = Logger.new($stdout, level: Logger::DEBUG)
      @ruby_llm = RubyLLMConfig.new
      @prompts = PromptsConfig.new
    end

    # Configure RubyLLM with current settings from the `RubyLLMConfig` config object.
    def configure_llm!
      require "ruby_llm" unless defined?(RubyLLM)

      RubyLLM.configure do |config|
        RubyLLMConfig.supported_attributes.each do |attr|
          value = @ruby_llm.public_send(attr)          
          config.public_send("#{attr}=", value) unless value.nil?
        end
      end
    end
  end
end

# frozen_string_literal: true

require_relative 'deepsearch/version'
require_relative 'deepsearch/logger'
require_relative 'deepsearch/configuration'
require_relative 'deepsearch/engine'
require_relative 'search_adapters'

# The main module for the Deepsearch gem.
# It provides the primary interface for configuration and for initiating searches.
module Deepsearch
  # A generic error class for exceptions raised by the Deepsearch gem,
  # from which more specific errors can inherit.
  class Error < StandardError; end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
      configuration.configure_llm!
    end

    def reset_configuration!
      @configuration = Configuration.new
    end

    def search(query, adapter_type: nil, **options)
      engine = Engine.new(adapter_type: adapter_type)
      engine.search(query, **options)
    end

    def engine(adapter_type: nil)
      Engine.new(adapter_type: adapter_type)
    end
  end
end

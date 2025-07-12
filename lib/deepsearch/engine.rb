# frozen_string_literal: true

require_relative "engine/pipeline"

module Deepsearch
  # The main entry point for performing a deep search.
  # This class initializes the search pipeline with the configured or specified
  # search adapter and provides a `search` method to execute the query.
  class Engine
    attr_reader :pipeline

    def initialize(adapter_type: nil)
      adapter_source = adapter_type ||
                       Deepsearch.configuration.custom_search_adapter_class ||
                       Deepsearch.configuration.search_adapter

      search_adapter = Deepsearch::SearchAdapters.create(adapter_source)
      @pipeline = Engine::Pipeline.new(search_adapter)
    end

    def search(query, **options)
      @pipeline.execute(query, **options)
    end
  end
end

# frozen_string_literal: true

require_relative 'search_adapters/tavily_adapter'
require_relative 'search_adapters/mock_adapter'
require_relative 'search_adapters/serper_adapter'

module Deepsearch
  module SearchAdapters
    def self.create(type, *args)
      return type.new(*args) if type.is_a?(Class)

      case type.to_sym
      when :tavily
        TavilyAdapter.new(*args)
      when :serper
        SerperAdapter.new(*args)
      when :mock
        MockAdapter.new(*args)
      else
        raise ArgumentError, "Unknown or invalid adapter type: #{type}"
      end
    end
  end
end

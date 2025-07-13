# frozen_string_literal: true

require_relative "test_helper"

class SearchAdaptersTest < Minitest::Test
  def test_creates_tavily_adapter
    adapter = Deepsearch::SearchAdapters.create(:tavily, "tvly-test_key")
    assert_instance_of Deepsearch::SearchAdapters::TavilyAdapter, adapter
  end

  def test_creates_serper_adapter
    adapter = Deepsearch::SearchAdapters.create(:serper, "serper-test_key")
    assert_instance_of Deepsearch::SearchAdapters::SerperAdapter, adapter
  end

  def test_creates_mock_adapter
    adapter = Deepsearch::SearchAdapters.create(:mock)
    assert_instance_of Deepsearch::SearchAdapters::MockAdapter, adapter
  end

  def test_creates_custom_adapter_class
    custom_adapter = Class.new do
      def initialize; end
      def search(_query, _options = {}); end
    end

    adapter = Deepsearch::SearchAdapters.create(custom_adapter)
    assert_instance_of custom_adapter, adapter
  end

  def test_raises_for_unknown_adapter_type
    assert_raises(ArgumentError) do
      Deepsearch::SearchAdapters.create(:unknown)
    end
  end
end

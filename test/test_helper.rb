# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'deepsearch'

require 'stringio'
require 'minitest/autorun'
require 'minitest/mock'

require_relative 'support/llm_mock'

class Minitest::Test
  def before_setup
    Deepsearch.configure do |config|
      config.logger = Deepsearch::Logger.new(StringIO.new)
    end
  end
end

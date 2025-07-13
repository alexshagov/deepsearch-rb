# frozen_string_literal: true

# This file mocks the RubyLLM constant to avoid loading the actual gem in tests.
# The constant needs to exist so that we can stub its methods.
module RubyLLM
  # Mocked class-level method for chat interactions.
  def self.chat; end

  # Mocked class-level method for generating embeddings.
  def self.embed(_text); end
end

# frozen_string_literal: true

require_relative "test_helper"

class DeepsearchTest < Minitest::Test
  def test_it_has_a_version_number
    refute_nil Deepsearch::VERSION
  end

  def teardown
    Deepsearch.reset_configuration!
  end
end

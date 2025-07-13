# frozen_string_literal: true

require_relative "../../../test_helper"
require "deepsearch/engine/steps/data_aggregation/process"
require "deepsearch/engine/steps/data_aggregation/parsed_website"

module Deepsearch
  class Engine
    module Steps
      module DataAggregation
        class ProcessTest < Minitest::Test
          def setup
            @websites = [
              { 'url' => 'http://example.com/success' },
              { 'url' => 'http://example.com/failure' }
            ]
          end

          def test_execute_aggregates_successful_websites
            # Arrange
            successful_website = ParsedWebsite.allocate.tap { |p| p.instance_variable_set(:@success, true) }
            failed_website = ParsedWebsite.allocate.tap { |p| p.instance_variable_set(:@success, false) }

            ParsedWebsite.stub :new, lambda { |url:|
              url == 'http://example.com/success' ? successful_website : failed_website
            } do
              process = Process.new(websites: @websites)

              # Act
              result = process.execute

              # Assert
              assert result.success?
              assert_equal 1, result.parsed_websites.size
              assert_equal successful_website, result.parsed_websites.first
            end
          end

          def test_execute_handles_no_successful_websites
            # Arrange
            failed_website = ParsedWebsite.allocate.tap { |p| p.instance_variable_set(:@success, false) }

            ParsedWebsite.stub :new, failed_website do
              process = Process.new(websites: [{ 'url' => 'http://example.com/failure' }])

              # Act
              result = process.execute

              # Assert
              assert result.success?
              assert_empty result.parsed_websites
            end
          end
        end
      end
    end
  end
end

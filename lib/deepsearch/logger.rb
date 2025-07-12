# frozen_string_literal: true

require 'logger'
require 'forwardable'

module Deepsearch
  # A custom logger that wraps Ruby's standard `::Logger` to provide a default format.
  class Logger
    extend Forwardable

    def_delegators :@logger, :debug, :level=, :level, :progname=, :progname, :formatter=, :formatter

    # Re-exporting constants from ::Logger for compatibility.
    DEBUG = ::Logger::DEBUG

    def initialize(logdev, level: DEBUG, progname: 'DeepSearch', formatter: nil)
      @logger = ::Logger.new(logdev)
      @logger.level = level
      @logger.progname = progname
      @logger.formatter = formatter || default_formatter
    end

    private

    def default_formatter
      proc do |severity, datetime, progname, msg|
        formatted_time = datetime.strftime('%Y-%m-%d %H:%M:%S.%L')
        "[#{formatted_time}] #{severity.ljust(5)} -- #{progname}: #{msg}\n"
      end
    end
  end
end
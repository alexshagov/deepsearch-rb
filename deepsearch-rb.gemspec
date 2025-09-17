# frozen_string_literal: true

require_relative "lib/deepsearch/version"

Gem::Specification.new do |spec|
  spec.name = "deepsearch-rb"
  spec.version = Deepsearch::VERSION
  spec.authors = ["Alexander Shagov"]
  spec.email = ["shagov.dev@outlook.com"]

  spec.summary = "A ruby gem for performing LLM-powered automated web search."
  spec.description = "A ruby gem for performing LLM-powered automated web search."
  spec.homepage = "https://github.com/alexshagov/deepsearch-rb"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/alexshagov/deepsearch-rb"
  spec.metadata["changelog_uri"] = "https://github.com/alexshagov/deepsearch-rb/blob/main/CHANGELOG.md"

  spec.files = Dir.glob("lib/**/*") + %w[README.md LICENSE.txt CHANGELOG.md]
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "nokogiri", ">= 1.10"
  spec.add_dependency "async", ">= 2.0"
  spec.add_dependency "ruby_llm", ">= 1.6"

  # Development dependencies
  spec.add_development_dependency "bundler", ">= 2.0"
  spec.add_development_dependency "rake", ">= 13.0"
  spec.add_development_dependency "minitest", ">= 5.0"
  spec.add_development_dependency "ostruct"
  spec.add_development_dependency "yard", ">= 0.9"
end

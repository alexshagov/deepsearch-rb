#!/usr/bin/env ruby
# frozen_string_literal: true

require "deepsearch"
require "async"
require "pastel"
require "fileutils"

# ========= CONFIGURATION =========

Deepsearch.configure do |config|
  config.search_adapter = :serper
  config.serper_api_key = ENV['SERPER_API_KEY']
  config.ruby_llm.gemini_api_key = ENV['GEMINI_API_KEY']
  config.ruby_llm.default_model = 'gemini-2.0-flash-lite'
  config.ruby_llm.default_embedding_model = 'text-embedding-004'
end

MAX_DEPTH          = 2
BRANCHING_FACTOR   = 2
REPORTS_DIR        = "reports"

PastelInst = Pastel.new
FileUtils.mkdir_p(REPORTS_DIR)

# ========= HELPERS =========
def llm(prompt)
  RubyLLM.chat.ask(prompt).content.strip
end

def rephrase_if_vague(query)
  llm("Turn the vague topic “#{query}” into a precise search-engine sentence (output only that sentence).")
end

def deepen_queries(parent_summary, amount)
  prompt = <<~TEXT
    Generate #{amount} concise follow-up search queries that will extend the following summary. One query per line, no bullets.

    Summary:
    #{parent_summary}
  TEXT
  llm(prompt).split("\n").map(&:strip).reject(&:empty?).first(amount)
end

# ========= NODE WORKER =========
class ResearchNode
  attr_reader :query, :level, :parent_id_array, :id

  def initialize(query:, level:, parent_id_array: [])
    @query          = query
    @level          = level
    @parent_id_array = parent_id_array
    @id             = [*parent_id_array, SecureRandom.uuid]
  end

  def display_breadcrumb
    prefix = "#{'  ' * level}▸ "
    puts PastelInst.cyan("#{prefix}#{query}")
  end

  def run
    display_breadcrumb

    effective_query = level.zero? ? rephrase_if_vague(query) : query

    result = Deepsearch.search(effective_query, max_total_search_results: 30 - (level * 4))
    puts PastelInst.green("  -> ResearchNode completed")
    raise result.error if result.failure?

    File.write(md_path, result.summary)

    return if level == MAX_DEPTH

    deps = deepen_queries(result.summary, BRANCHING_FACTOR)
    Async do |task|
      deps.each do |sub_q|
        task.async do
          puts PastelInst.green("  -> Starting sub-research for: '#{sub_q}'")
          ResearchNode.new(query: sub_q,
                           level: level + 1,
                           parent_id_array: @id).run
        end
      end
    end
  end

  def md_path
    safe_name = id.join('-').gsub(/[^\w\-]/, '_')
    File.join(REPORTS_DIR, "#{safe_name}.md")
  end
end

# ========= ENTRY =========
if $0 == __FILE__
  root = ARGV.first
  ResearchNode.new(query: root, level: 0).run
end
# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'nokogiri'

module Deepsearch
  class Engine
    module Steps
      module DataAggregation
        # Fetches content from a URL, parses it, and cleans it to extract meaningful text.
        # It handles HTTP requests, content type detection, and removal of unwanted HTML elements.
        class ParsedWebsite
          attr_reader :url, :content, :success, :error, :metadata, :timestamp

          def initialize(url:)
            @url = url
            @content = nil
            @success = false
            @error = nil
            fetch_content!
          end

          def success?
            @success
          end

          def size
            content.to_s.size
          end

          def to_h
            {
              url: url,
              success: success?,
              error: error,
              content: content
            }
          end

          protected

          def fetch_content!
            uri = URI.parse(@url)

            unless %w[http https].include?(uri.scheme)
              @error = "Invalid URL scheme: #{uri.scheme}"
              return
            end

            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = uri.scheme == 'https'
            http.read_timeout = 10
            http.open_timeout = 5

            request = Net::HTTP::Get.new(uri.request_uri)
            request['User-Agent'] = random_user_agent

            response = http.request(request)

            if response.is_a?(Net::HTTPSuccess)
              body = response.body.encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
              @content = clean_content(body)
              @success = true
            else
              @error = "HTTP #{response.code}"
            end
          rescue StandardError => e
            @error = e.message
          end

          private

          def random_user_agent
            [
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 DeepSearch/1.0',
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 DeepSearch/1.0',
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Safari/605.1.15 DeepSearch/1.0',
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/115.0 DeepSearch/1.0'
            ].sample
          end

          def clean_content(content)
            raw_content = content.to_s
            # If not HTML, we still need to make sure it's valid UTF-8 for JSON serialization.
            unless raw_content =~ /<html[\s>]|<!DOCTYPE html/i
              return raw_content.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
            end

            # Let Nokogiri parse the raw bytes and detect encoding
            doc = Nokogiri::HTML(raw_content)

            # Remove unwanted elements
            doc.css('script, style, head, meta, link, noscript, iframe, svg, img').remove

            # Remove comments
            doc.xpath('//comment()').remove

            # Remove inline styles and event handlers
            doc.css('*').each do |node|
              node.remove_attribute('style')
              node.remove_attribute('onclick')
              node.remove_attribute('onload')
              node.remove_attribute('onerror')
            end

            # Get text content and clean it up
            text = (doc.at('body')&.text || doc.text).to_s
            utf8_text = text.encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
            utf8_text.gsub(/[[:space:]]+/, ' ').strip
          rescue StandardError
            # Fallback if Nokogiri fails. The raw_content is the problem. Sanitize it from binary to UTF-8.
            fallback_text = content.to_s.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
            fallback_text.gsub(%r{<script\b[^>]*>.*?</script>}mi, '').gsub(%r{<style\b[^>]*>.*?</style>}mi, '').gsub(
              /[[:space:]]+/, ' '
            ).strip
          end
        end
      end
    end
  end
end

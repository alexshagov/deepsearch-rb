# frozen_string_literal: true

module Deepsearch
  module SearchAdapters
    # A mock search adapter for testing purposes.
    # It returns a static, predefined set of search results without making any external API calls.
    # This is useful for testing the pipeline's behavior in isolation from live search services.
    class MockAdapter
      def initialize(api_key = nil); end

      def search(query, options = {})
        mock_results(query, options)
      end

      private

      def mock_results(query, options = {})
        max_results = options[:max_results] || 10
        include_answer = options[:include_answer] != false

        results = [
          {
            'title' => 'Ruby (programming language) - Wikipedia',
            'url' => 'https://en.wikipedia.org/wiki/Ruby_(programming_language)',
            'content' => 'Ruby is a general-purpose programming language. It was designed with an emphasis on programming productivity and simplicity. In Ruby, everything is an object, including primitive data types. It was developed in the mid-1990s by Yukihiro Matsumoto in Japan.',
            'published_date' => '2024-01-15'
          },
          {
            'title' => 'Ruby Programming Language - GeeksforGeeks',
            'url' => 'https://www.geeksforgeeks.org/ruby/ruby-programming-language/',
            'content' => 'Ruby is a dynamic, reflective, object-oriented, general-purpose programming language. Ruby is a pure object-oriented language developed by Yukihiro Matsumoto. Everything in Ruby is an object except the blocks but there are replacements too.',
            'published_date' => '2024-02-10'
          },
          {
            'title' => 'Ruby Programming Language',
            'url' => 'https://www.ruby-lang.org/en/',
            'content' => '# Ruby # Ruby is... A dynamic, open source programming language with a focus on natural to read and easy to write code. It has an elegant syntax that is natural to read and easy to write.',
            'published_date' => '2024-03-01'
          },
          {
            'title' => 'About Ruby',
            'url' => 'https://www.ruby-lang.org/en/about/',
            'content' => "About Ruby About Ruby About Ruby's Growth In Ruby, everything is an object. ruby Ruby follows the information-hiding principle where the implementation details are hidden and only the necessary information is exposed.",
            'published_date' => '2024-02-20'
          },
          {
            'title' => "What's Ruby used for most nowadays? - Reddit",
            'url' => 'https://www.reddit.com/r/ruby/comments/yhe3t4/whats_ruby_used_for_most_nowadays/',
            'content' => "Ruby is mainly used in web app development because that's what makes money. However, Ruby is also used for automation, data processing, DevOps tools, and many other applications where its expressive syntax shines.",
            'published_date' => '2024-01-30'
          }
        ]

        limited_results = results.take(max_results)

        response = {
          'query' => query,
          'follow_up_questions' => [],
          'images' => [],
          'results' => limited_results,
          'search_depth' => options[:search_depth] || 'basic',
          'search_time' => 0.1
        }

        if include_answer
          response['answer'] =
            "Ruby is a dynamic, open-source programming language with a focus on simplicity and productivity. It was created by Yukihiro Matsumoto in the mid-1990s and follows the principle that everything is an object. Ruby is particularly popular for web development, especially with the Ruby on Rails framework, but it's also used for automation, data processing, and various other applications."
        end

        response
      end
    end
  end
end

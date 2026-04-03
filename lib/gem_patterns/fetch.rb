# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

module GemPatterns
  # Fetch gem metadata from RubyGems API
  class Fetch
    URL = 'https://rubygems.org/api/v1/gems/%s.json'

    def call(name)
      return @cache[name] if @cache&.key?(name)

      @cache ||= {}
      @cache[name] = JSON.parse(Net::HTTP.get_response(URI.parse(URL % name)).body)
    rescue StandardError => e
      warn "Fetch #{name}: #{e.message}"
      nil
    end
  end
end

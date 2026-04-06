# frozen_string_literal: true

require_relative '../gem_patterns/config'

module ContentAdapter
  module TldrToEntry
    def self.call(parsed)
      {
        gem_name: parsed[:command],
        description: parsed[:description],
        category: parsed[:platform] || 'common',
        scenarios: parsed[:examples].map do |ex|
          { trigger: ex[:description], snippet: ex[:command], gotchas: [] }
        end,
        failure_modes: [],
        meta: { invasiveness: 2, coupling: 2 },
        raw_content_hash: parsed[:content_hash],
        created_at: Time.now.utc.iso8601,
        version: GemPatterns::VERSION
      }
    end
  end
end

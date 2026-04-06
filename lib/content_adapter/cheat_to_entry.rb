# frozen_string_literal: true

require_relative '../gem_patterns/config'

module ContentAdapter
  module CheatToEntry
    def self.call(parsed)
      {
        gem_name: parsed[:command],
        description: parsed[:description] || "Cheatsheet for #{parsed[:command]}",
        category: parsed[:tags]&.first || 'general',
        scenarios: parsed[:examples].map do |ex|
          { trigger: ex[:comment], snippet: ex[:command], gotchas: [] }
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

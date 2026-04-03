# frozen_string_literal: true

module GemPatterns
  class Build
    def call(name:, data: nil, llm_result: nil)
      {
        gem_name: name,
        description: data&.dig('info') || '',
        category: categorize(name),
        scenarios: llm_result&.dig('scenarios') || [],
        failure_modes: llm_result&.dig('failure_modes') || [],
        meta: llm_result&.dig('meta') || { invasiveness: 2, coupling: 2 },
        created_at: Time.now.utc.iso8601,
        version: GemPatterns::VERSION
      }
    end

    private

    def categorize(name)
      n = name.downcase
      return 'runtime' if n.include?('active_support') || n.include?('dry-')
      return 'rails' if n.include?('rails')
      return 'http' if n.include?('http') || n.include?('faraday')
      return 'db' if n.include?('sequel') || n.include?('pg')

      'application'
    end
  end
end

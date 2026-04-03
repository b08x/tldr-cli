# frozen_string_literal: true

module GemPatterns
  class ScenarioWriter
    def initialize(db, embedder)
      @db = db
      @embedder = embedder
    end

    def write(pattern_id, scenarios)
      return if scenarios.empty?

      @db[:scenarios].where(pattern_id: pattern_id).delete
      @db[:scenarios].multi_insert(rows(pattern_id, scenarios))
    end

    private

    def rows(pattern_id, scenarios)
      scenarios.map do |s|
        {
          pattern_id: pattern_id,
          trigger: s[:trigger],
          snippet: s[:snippet],
          gotchas: JSON.generate(s[:gotchas] || []),
          embedding: @embedder.call(s[:trigger].to_s)
        }
      end
    end
  end
end

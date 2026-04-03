# frozen_string_literal: true

require 'sequel'

module GemPatterns
  # Schema management — runs migration 001 on first connect
  class Schema
    MIGRATION_PATH = File.expand_path('../../../db/migrate/001_initial_schema.rb', __dir__)

    def self.ensure(db)
      return if db.tables.include?(:patterns) && db.tables.include?(:scenarios)

      Sequel::Migrator.run(db, File.dirname(MIGRATION_PATH))
    end
  end
end

# frozen_string_literal: true

module GemPatterns
  VERSION = '0.2.0'

  module Config
    def self.database_url
      ENV.fetch('DATABASE_URL', 'postgres://localhost/gem_patterns')
    end

    def self.gems_csv
      File.expand_path('../../../gems-inventory.csv', __dir__)
    end
  end
end

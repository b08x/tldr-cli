# frozen_string_literal: true

module GemPatterns
  VERSION = '0.3.0'

  module Config
    def self.database_url
      ENV.fetch('DATABASE_URL', 'postgres://localhost/gem_patterns')
    end

    def self.gems_csv
      File.expand_path('../../../gems-inventory.csv', __dir__)
    end

    def self.tldr_repo
      ENV.fetch('TLDR_REPO', 'tldr-pages/tldr')
    end

    def self.cheat_repo
      ENV.fetch('CHEAT_REPO', 'cheat/cheatsheets')
    end

    def self.language
      ENV.fetch('TLDR_LANGUAGE', 'en')
    end

    def self.platform
      ENV.fetch('TLDR_PLATFORM', 'common')
    end
  end
end

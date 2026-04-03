# frozen_string_literal: true

require 'sequel'

module GemPatterns
  class Store
    def initialize(db: nil, embedder: nil)
      @db = db || Sequel.connect(GemPatterns::Config.database_url)
      @db.extension :pgvector
      @embedder = embedder || Embedder.new
      Schema.ensure(@db)
    end

    def reset
      @db[:scenarios].truncate
      @db[:patterns].truncate
    end

    def index(entry)
      hash = ContentHasher.call(entry)
      return :skipped if @db[:patterns].where(content_hash: hash).first

      vec = @embedder.call(EntryEmbedder.call(entry))
      @db.transaction do
        pid = PatternUpsert.call(@db, entry, vec, hash)
        ScenarioWriter.new(@db, @embedder).write(pid, entry[:scenarios] || [])
      end
      :indexed
    rescue StandardError => e
      warn "Index error [#{e.class}] #{entry[:gem_name]}: #{e.message}"
      :error
    end
  end

  class EntryEmbedder
    def self.call(entry)
      [entry[:description], (entry[:scenarios] || []).map { |s| s[:trigger] }].compact.join(' ')
    end
  end

  class PatternUpsert
    def self.call(db, entry, vec, hash)
      attrs = {
        gem_name: entry[:gem_name], description: entry[:description],
        category: entry[:category], scenarios: JSON.generate(entry[:scenarios] || []),
        failure_modes: JSON.generate(entry[:failure_modes] || []),
        meta: JSON.generate(entry[:meta] || {}), embedding: vec,
        content_hash: hash, schema_version: '1'
      }
      db[:patterns]
        .insert_conflict(target: :gem_name, update: attrs.reject { |_, v| v.nil? })
        .returning(:id)
        .insert(attrs)
        .first[:id]
    end
  end
end

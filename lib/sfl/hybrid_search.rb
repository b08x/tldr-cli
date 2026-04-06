# frozen_string_literal: true

require 'sequel'
require_relative '../gem_patterns/config'
require_relative '../gem_patterns/embedder'

module SFL
  class HybridSearch
    def initialize(db: nil, embedder: nil)
      @db = db || Sequel.connect(GemPatterns::Config.database_url)
      @embedder = embedder || GemPatterns::Embedder.new
    end

    def call(query, sfl_filters: {}, top_k: 5)
      vec = @embedder.call(query)
      ds = base_query(vec)
      ds = apply_sfl_filters(ds, sfl_filters)
      ds.limit(top_k).all
    end

    def count
      @db[:clauses].count
    end

    private

    def base_query(vec)
      @db[:clauses]
        .select(:id, :raw_text, :process_type, :mood_type, :theme_type,
                :ideational_structure, :interpersonal_structure, :textual_structure,
                Sequel.lit('(embedding <=> ?) AS distance', "[#{vec.join(',')}]"))
        .order(Sequel.asc(Sequel.lit('embedding <=> ?', "[#{vec.join(',')}]")))
    end

    def apply_sfl_filters(ds, filters)
      ds = ds.where(process_type: filters[:process_type]) if filters[:process_type]
      ds = ds.where(mood_type: filters[:mood_type]) if filters[:mood_type]
      ds = ds.where(theme_type: filters[:theme_type]) if filters[:theme_type]
      if filters[:participant_role]
        ds = ds.where(
          Sequel.lit('ideational_structure @> ?',
                     { participants: [{ role: filters[:participant_role] }] }.to_json)
        )
      end
      if filters[:modality]
        ds = ds.where(
          Sequel.lit("interpersonal_structure ->> 'modality' = ?", filters[:modality])
        )
      end
      ds
    end
  end
end

# frozen_string_literal: true

require 'sequel'
require 'set'

module GemPatterns
  class Search
    # NOTE: This is NOT true Reciprocal Rank Fusion (RRF).
    # It uses vector-first concatenation with deduplication.
    # Vector results always rank above keyword-only matches.
    # True RRF would score: 1/(k+rank_vec) + 1/(k+rank_kw).

    def initialize(db: nil, embedder: nil)
      @db = db || Sequel.connect(GemPatterns::Config.database_url)
      @embedder = embedder || Embedder.new
    end

    def call(query, top_k: 5, mode: :hybrid)
      case mode
      when :vector   then vector_search(query, top_k)
      when :keyword  then keyword_search(query, top_k)
      else                hybrid_search(query, top_k)
      end
    end

    def count
      @db[:patterns].count
    end

    private

    def vector_search(query, top_k)
      vec = @embedder.call(query)
      @db[:patterns]
        .order(Sequel.lit('embedding <=> ?', "[#{vec.join(',')}]"))
        .limit(top_k).all
    end

    def keyword_search(query, top_k)
      @db[:patterns]
        .where { gem_name.ilike("%#{query}%") | description.ilike("%#{query}%") }
        .order(Sequel.desc(Sequel.lit('GREATEST(similarity(gem_name, ?), similarity(description, ?))', query, query)))
        .limit(top_k).all
    end

    def hybrid_search(query, top_k)
      vec_results = vector_search(query, top_k * 2)
      kw_results  = keyword_search(query, top_k * 2)
      dedup(vec_results + kw_results, top_k)
    end

    def dedup(results, top_k)
      seen = Set.new
      results.each_with_object([]) do |r, acc|
        next if seen.include?(r[:gem_name])

        seen.add(r[:gem_name])
        acc << r
        break acc if acc.size >= top_k
      end
    end
  end
end

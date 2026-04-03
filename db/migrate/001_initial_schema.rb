# frozen_string_literal: true

Sequel.migration do
  up do
    # Extensions — always first
    run 'CREATE EXTENSION IF NOT EXISTS vector'        # pgvector for semantic search
    run 'CREATE EXTENSION IF NOT EXISTS pg_trgm'       # trigram fuzzy matching
    run 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp"'   # UUID v4 generation

    # patterns — gem pattern entries with vector embeddings
    create_table :patterns do
      primary_key :id, type: :uuid, default: Sequel.function(:uuid_generate_v4)
      String :gem_name, unique: true, null: false          # gem identity key
      String :description, text: true                      # gem purpose summary
      String :category                                     # domain classification
      column :scenarios, :jsonb, default: '[]'             # usage scenarios (denormalized cache)
      column :failure_modes, :jsonb, default: '[]'         # known failure patterns
      column :meta, :jsonb, default: '{}'                  # LLM-generated metadata
      column :embedding, 'vector(384)'                     # all-MiniLM-L6-v2 (locked at 384)
      String :content_hash, unique: true                   # SHA256 idempotency gate
      String :schema_version, default: '1'                 # tracks migration version
      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, default: Sequel::CURRENT_TIMESTAMP

      # HNSW — sub-ms ANN retrieval, superior recall vs IVFFlat
      add_index :embedding, type: 'hnsw', opclass: 'vector_cosine_ops',
                            name: 'patterns_embedding_hnsw_idx'
      # GIN — enables @> containment queries on JSONB columns
      add_index :scenarios, type: :gin, name: 'patterns_scenarios_gin_idx'
      add_index :failure_modes, type: :gin, name: 'patterns_failure_modes_gin_idx'
      add_index :meta, type: :gin, name: 'patterns_meta_gin_idx'
      # trgm — fuzzy keyword search on gem_name (e.g. "sequel" vs "sequle")
      add_index :gem_name, opclass: :gin_trgm_ops, name: 'patterns_gem_name_trgm_idx'
      add_index :description, opclass: :gin_trgm_ops, name: 'patterns_description_trgm_idx'
      index :content_hash
      index :category
    end

    # scenarios — normalized per-scenario rows for individual searchability
    create_table :scenarios do
      primary_key :id, type: :uuid, default: Sequel.function(:uuid_generate_v4)
      foreign_key :pattern_id, :patterns, type: :uuid, on_delete: :cascade, null: false
      String :trigger, null: false                         # when this pattern applies
      String :snippet, text: true                          # code example
      column :gotchas, :jsonb, default: '[]'               # pitfalls / warnings
      column :embedding, 'vector(384)'                     # per-scenario embedding
      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP

      # HNSW — per-scenario semantic search (e.g. "retry with backoff")
      add_index :embedding, type: 'hnsw', opclass: 'vector_cosine_ops',
                            name: 'scenarios_embedding_hnsw_idx'
      # trgm — fuzzy search on trigger text
      add_index :trigger, opclass: :gin_trgm_ops, name: 'scenarios_trigger_trgm_idx'
      # GIN — containment queries on gotchas array
      add_index :gotchas, type: :gin, name: 'scenarios_gotchas_gin_idx'
      index :pattern_id
    end
  end

  down do
    drop_table :scenarios
    drop_table :patterns
  end
end

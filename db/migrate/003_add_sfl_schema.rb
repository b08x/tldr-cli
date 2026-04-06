# frozen_string_literal: true

Sequel.migration do
  up do
    # Extensions (idempotent — 001 may have created these)
    run 'CREATE EXTENSION IF NOT EXISTS vector'
    run 'CREATE EXTENSION IF NOT EXISTS pg_trgm'
    run 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp"'

    # clauses — primary SFL meaning unit
    create_table :clauses do
      primary_key :id, type: :uuid, default: Sequel.function(:uuid_generate_v4)
      foreign_key :scenario_id, :scenarios, type: :uuid, on_delete: :cascade, null: true
      foreign_key :parent_complex_id, :clauses, type: :uuid, null: true, on_delete: :set_null
      Integer :sequence_index
      String :raw_text, text: true, null: false
      String :content_hash, null: false, unique: true

      # Ideational — Transitivity
      String :process_type, null: false
      constraint :valid_process_type,
                 process_type: %w[material mental relational verbal behavioural existential]
      String :process_lemma
      column :ideational_structure, :jsonb, default: '{}'

      # Interpersonal — Mood
      String :mood_type
      constraint :valid_mood_type,
                 mood_type: %w[declarative interrogative imperative exclamative minor]
      column :interpersonal_structure, :jsonb, default: '{}'

      # Textual — Theme/Rheme
      String :theme_type
      column :textual_structure, :jsonb, default: '{}'

      # Vector — 384-dim (all-MiniLM-L6-v2)
      column :embedding, 'vector(384)'

      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
    end

    # HNSW for ANN cosine similarity
    add_index :clauses, :embedding, type: 'hnsw', opclass: 'vector_cosine_ops',
                                    name: 'clauses_embedding_hnsw_idx'
    # GIN for JSONB containment
    add_index :clauses, :ideational_structure, type: :gin, name: 'clauses_ideational_gin_idx'
    add_index :clauses, :interpersonal_structure, type: :gin, name: 'clauses_interpersonal_gin_idx'
    add_index :clauses, :textual_structure, type: :gin, name: 'clauses_textual_gin_idx'
    index :clauses, :process_type
    index :clauses, :mood_type
    index :clauses, :theme_type
    index :clauses, :content_hash

    # tokens — atomic lexical units (ruby-spacy output)
    create_table :tokens do
      primary_key :id, type: :uuid, default: Sequel.function(:uuid_generate_v4)
      foreign_key :clause_id, :clauses, type: :uuid, on_delete: :cascade
      String :text, null: false
      String :lemma
      String :pos_tag
      String :tag_
      String :dependency_label
      Boolean :is_stop, default: false
      Boolean :is_punct, default: false
      Integer :index_in_clause
      column :morphological_forms, :jsonb, default: '{}'

      index :tokens, :lemma, opclass: :gin_trgm_ops, name: 'tokens_lemma_trgm_idx'
      index :tokens, :pos_tag
      index :tokens, :dependency_label
    end

    # participants — polymorphic participant roles
    create_table :participants do
      primary_key :id, type: :uuid, default: Sequel.function(:uuid_generate_v4)
      foreign_key :clause_id, :clauses, type: :uuid, on_delete: :cascade, null: false
      String :role, null: false
      constraint :valid_role,
                 role: %w[actor goal beneficiary senser phenomenon sayer verbiage receiver
                          carrier attribute token value behaver existent]
      Text :entity_text
      String :ner_label
      String :dep_label
      column :embedding, 'vector(384)'

      add_index :participants, :embedding, type: 'hnsw', opclass: 'vector_cosine_ops',
                                           name: 'participants_embedding_hnsw_idx'
      index :participants, :role
      index :participants, :dep_label
    end
  end

  down do
    drop_table :participants
    drop_table :tokens
    drop_table :clauses
  end
end

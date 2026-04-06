# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table :patterns do
      add_column :source, String, default: 'gem'
      add_column :platform, String
      add_column :raw_content_hash, String
    end
    add_index :patterns, :source
    add_index :patterns, :platform
    add_index :patterns, :raw_content_hash, unique: true
  end

  down do
    drop_index :patterns, :raw_content_hash
    drop_index :patterns, :platform
    drop_index :patterns, :source
    alter_table :patterns do
      drop_column :raw_content_hash
      drop_column :platform
      drop_column :source
    end
  end
end

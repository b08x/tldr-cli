# frozen_string_literal: true

require 'rake'
require 'fileutils'

namespace :gem_patterns do
  desc 'Initialize pgvector database schema'
  task :init do
    puts 'Initializing pgvector database...'

    require_relative '../lib/gem_patterns'

    config = GemPatterns::Config.load
    store = GemPatterns::Storage::VectorStore.new(config: config)

    store.create_tables
    puts '✓ Schema initialized: patterns table with HNSW index'
  end

  desc 'Generate patterns for a tier (default: tier1)'
  task :generate, [:tier] do |_t, args|
    tier = args[:tier] || 'tier1'
    vector = ENV['VECTOR'] == 'true'

    puts "Generating #{tier} patterns (vector: #{vector})..."

    require_relative '../lib/gem_patterns'

    config = GemPatterns::Config.load
    generator = GemPatterns::PatternGenerator.new(config: config)

    generator.init_vector_store! if vector

    generator.generate_all(tier: tier.to_sym, vector_index: vector)

    puts "\n✓ Generation complete!"
    puts "  JSON output: #{generator.instance_variable_get(:@json_writer).output_dir}"
    puts "  Vector store: #{generator.vector_store.count} entries" if vector
  end

  desc 'Search patterns by query'
  task :search, [:query] do |_t, args|
    query = args[:query]
    raise "Usage: rake gem_patterns:search['query']" unless query

    puts "Searching for: #{query}"

    require_relative '../lib/gem_patterns'

    config = GemPatterns::Config.load
    store = GemPatterns::Storage::VectorStore.new(config: config)

    results = store.search(query)

    if results.empty?
      puts 'No results found'
    else
      results.each_with_index do |r, idx|
        puts "#{idx + 1}. #{r[:gem_name]} - #{r[:category]}"
        puts "   #{r[:description][0..80]}..."
      end
    end
  end

  desc 'List all indexed patterns'
  task :list do
    require_relative '../lib/gem_patterns'

    config = GemPatterns::Config.load
    store = GemPatterns::Storage::VectorStore.new(config: config)

    all = store.all

    puts "Total patterns: #{all.size}\n\n"

    all.each do |p|
      puts "  #{p[:gem_name].ljust(25)} #{p[:category]}"
    end
  end

  desc 'Drop all pattern data'
  task :reset do
    puts 'Dropping all patterns...'

    require_relative '../lib/gem_patterns'

    config = GemPatterns::Config.load
    store = GemPatterns::Storage::VectorStore.new(config: config)

    store.clear!
    puts '✓ All patterns cleared'
  end

  desc 'Run the CLI'
  task :cli do
    require_relative '../lib/gem_patterns/cli'

    GemPatterns::CLI.run(ARGV[2..-1])
  end
end

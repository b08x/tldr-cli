# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task default: :spec

# Gem Patterns tasks
require_relative "lib/gem_patterns"

namespace :gem_patterns do
  desc "Initialize pgvector schema"
  task :init do
    GemPatterns::Store.new
    puts "✓ Store initialized"
  end

  desc "Generate patterns (use VECTOR=1 for vector index)"
  task :generate do
    vector = ENV["VECTOR"] == "1"
    GemPatterns::Runner.new.run(vector: vector)
  end

  desc "Search patterns"
  task :search, [:query] do |_t, args|
    GemPatterns::Runner.new.search(args[:query])
  end

  desc "Show pattern count"
  task :count do
    store = GemPatterns::Store.new
    puts "#{store.count} patterns indexed"
  end

  desc "Reset the patterns database"
  task :reset do
    require_relative 'lib/gem_patterns'
    GemPatterns::Store.new.reset
    puts 'Database reset'
  end
end

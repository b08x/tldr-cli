# frozen_string_literal: true

module GemPatterns
  class CLI
    def initialize(runner: nil)
      @runner = runner || Runner.new
    end

    def run(args)
      case args[0]
      when 'generate' then @runner.run(all_gems)
      when 'search'   then @runner.search(args[1] || '').each do |r|
        puts "#{r[:gem_name]} - #{r[:description][0..50]}..."
      end
      when 'count'    then puts "#{@runner.count} patterns"
      when 'init'     then @runner.init && puts('DB initialized')
      else puts 'Usage: cli.rb <generate|search|count|init>'
      end
    end

    private

    def all_gems
      require 'csv'
      CSV.read(GemPatterns::Config.gems_csv, headers: true).map { |r| r['gem'] }.compact
    end
  end
end

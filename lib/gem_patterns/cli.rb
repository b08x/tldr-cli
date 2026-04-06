# frozen_string_literal: true

module GemPatterns
  class CLI
    def initialize(runner: nil)
      @runner = runner || Runner.new
    end

    def run(args)
      source = args[0] || 'gem'
      command = args[1]

      case source
      when 'gem' then run_gem(command, args[2..])
      when 'tldr' then puts 'tldr pipeline: coming soon'
      when 'cheat' then puts 'cheat pipeline: coming soon'
      else puts 'Usage: cli.rb <gem|tldr|cheat> <command>'
      end
    end

    private

    def run_gem(command, args)
      case command
      when 'generate' then @runner.run(all_gems)
      when 'search'   then @runner.search(args[0] || '').each do |r|
        puts "#{r[:gem_name]} - #{r[:description][0..50]}..."
      end
      when 'count'    then puts "#{@runner.count} patterns"
      when 'init'     then @runner.init && puts('DB initialized')
      else puts 'Usage: cli.rb gem <generate|search|count|init>'
      end
    end

    def all_gems
      require 'csv'
      CSV.read(GemPatterns::Config.gems_csv, headers: true).map { |r| r['gem'] }.compact
    end
  end
end

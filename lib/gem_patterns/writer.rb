# frozen_string_literal: true

require 'fileutils'
require 'json'

module GemPatterns
  # Write to JSON files
  class Writer
    def initialize(output_dir: nil)
      output_dir ||= File.expand_path('../../../output/patterns', __dir__)
      FileUtils.mkdir_p(output_dir)
    end

    def write(entry)
      dir = File.join(output_dir, entry[:category])
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, "#{entry[:gem_name]}.json"), JSON.pretty_generate(entry))
    end

    private

    attr_reader :output_dir
  end
end

# frozen_string_literal: true

require 'digest'

module CheatSheets
  class Parser
    def self.call(content, filename)
      new(content, filename).parse
    end

    def initialize(content, filename)
      @content = content
      @filename = filename
    end

    def parse
      {
        command: @filename,
        description: extract_description,
        tags: extract_tags,
        examples: extract_examples,
        content_hash: Digest::SHA256.hexdigest(@content)
      }
    end

    private

    def extract_description
      match = @content.match(/^# (.+?)$/)
      match ? match[1] : nil
    end

    def extract_tags
      match = @content.match(/^---\s*\ntags:\s*\[([^\]]+)\]/m)
      match ? match[1].split(',').map(&:strip) : []
    end

    def extract_examples
      blocks = @content.gsub(/^---.*?---\n?/m, '')
      blocks.scan(/^#\s*(.+?)\n((?:[^\n]+\n?)+)/m).map do |comment, commands|
        { comment: comment.strip, command: commands.strip }
      end
    end
  end
end

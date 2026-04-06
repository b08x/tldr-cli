# frozen_string_literal: true

require 'digest'

module TldrPages
  class Parser
    def self.call(content, platform: 'common')
      new(content, platform).parse
    end

    def initialize(content, platform)
      @content = content
      @platform = platform
    end

    def parse
      {
        command: command_name,
        description: extract_description,
        platform: @platform,
        examples: extract_examples,
        content_hash: Digest::SHA256.hexdigest(@content)
      }
    end

    private

    def command_name
      File.basename(@content.split("\n").first || '', '.md')
    end

    def extract_description
      match = @content.match(/^>\s*(.+?)$/)
      match ? match[1].gsub(/`([^`]+)`/, '\1').strip : ''
    end

    def extract_examples
      @content.scan(/^- (.+?):\n\n`(.+?)`/m).map do |desc, cmd|
        {
          description: desc.gsub(/`([^`]+)`/, '\1').strip,
          command: cmd.gsub(/\{\{([^}]+)\}\}/, '<\1>')
        }
      end
    end
  end
end

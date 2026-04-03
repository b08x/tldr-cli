# frozen_string_literal: true

require 'digest'
require 'json'

module GemPatterns
  module ContentHasher
    def self.call(entry)
      Digest::SHA256.hexdigest(canonical(entry))
    end

    def self.canonical(entry)
      [
        entry[:gem_name],
        entry[:description],
        JSON.generate(sort_keys(entry[:scenarios] || [])),
        JSON.generate(entry[:failure_modes] || []),
        JSON.generate(entry[:meta] || {})
      ].join('|')
    end

    def self.sort_keys(arr)
      arr.map { |h| h.is_a?(Hash) ? h.sort.to_h : h }
    end
    private_class_method :sort_keys
  end
end

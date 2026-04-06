# frozen_string_literal: true

require 'spec_helper'
require 'gem_patterns/content_hasher'

RSpec.describe GemPatterns::ContentHasher do
  let(:entry) do
    {
      gem_name: 'sequel',
      description: 'Database toolkit',
      scenarios: [{ trigger: 'need db', snippet: 'DB.connect', gotchas: ['timeout'] }],
      failure_modes: ['connection refused'],
      meta: { invasiveness: 2, coupling: 1 }
    }
  end

  describe '.call' do
    it 'returns a SHA256 hex string' do
      hash = described_class.call(entry)
      expect(hash).to match(/\A[a-f0-9]{64}\z/)
    end

    it 'is idempotent for the same input' do
      expect(described_class.call(entry)).to eq(described_class.call(entry))
    end

    it 'differs when meta changes' do
      modified = entry.merge(meta: { invasiveness: 3, coupling: 1 })
      expect(described_class.call(modified)).not_to eq(described_class.call(entry))
    end

    it 'differs when failure_modes changes' do
      modified = entry.merge(failure_modes: %w[timeout refused])
      expect(described_class.call(modified)).not_to eq(described_class.call(entry))
    end

    it 'is stable regardless of scenario key order' do
      reordered = entry.merge(
        scenarios: [{ snippet: 'DB.connect', trigger: 'need db', gotchas: ['timeout'] }]
      )
      expect(described_class.call(reordered)).to eq(described_class.call(entry))
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'
require 'gem_patterns/search'

RSpec.describe GemPatterns::Search do
  let(:db) { instance_double(Sequel::Database) }
  let(:embedder) { instance_double(GemPatterns::Embedder, call: [0.1] * 384) }
  let(:patterns_ds) { instance_double(Sequel::Dataset, order: nil, limit: nil, where: nil, count: 0) }

  subject { described_class.new(db: db, embedder: embedder) }

  before do
    allow(Sequel).to receive(:connect).and_return(db)
    allow(db).to receive(:[]).with(:patterns).and_return(patterns_ds)
    allow(Sequel).to receive(:lit).and_call_original
    allow(Sequel).to receive(:desc).and_call_original
  end

  describe '#call' do
    context 'with :vector mode' do
      before { allow(patterns_ds).to receive(:all).and_return([]) }

      it 'calls embedder and queries patterns' do
        subject.call('query', mode: :vector)
        expect(embedder).to have_received(:call).with('query')
      end
    end

    context 'with :keyword mode' do
      before { allow(patterns_ds).to receive(:all).and_return([]) }

      it 'queries with ilike' do
        subject.call('sequel', mode: :keyword)
        expect(patterns_ds).to have_received(:where)
      end
    end

    context 'with :hybrid mode (default)' do
      before { allow(patterns_ds).to receive(:all).and_return([]) }

      it 'runs both vector and keyword searches' do
        subject.call('query')
        expect(embedder).to have_received(:call).with('query')
      end
    end
  end

  describe '#count' do
    it 'returns pattern count' do
      allow(patterns_ds).to receive(:count).and_return(42)
      expect(subject.count).to eq(42)
    end
  end
end

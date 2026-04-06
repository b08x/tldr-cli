# frozen_string_literal: true

require 'spec_helper'
require 'gem_patterns/store'
require 'gem_patterns/content_hasher'
require 'gem_patterns/scenario_writer'

RSpec.describe GemPatterns::Store do
  let(:db) { instance_double(Sequel::Database, extension: nil, transaction: nil) }
  let(:embedder) { instance_double(GemPatterns::Embedder, call: [0.1] * 384) }
  let(:entry) do
    {
      gem_name: 'sequel',
      description: 'Database toolkit',
      scenarios: [{ trigger: 'need db', snippet: 'DB.connect', gotchas: [] }],
      failure_modes: [],
      meta: {}
    }
  end
  let(:patterns_ds) { instance_double(Sequel::Dataset, where: nil, insert_conflict: nil) }
  let(:scenarios_ds) { instance_double(Sequel::Dataset, where: nil, multi_insert: nil) }

  subject { described_class.new(db: db, embedder: embedder) }

  before do
    allow(Sequel).to receive(:connect).and_return(db)
    allow(GemPatterns::Schema).to receive(:ensure)
    allow(db).to receive(:[]).with(:patterns).and_return(patterns_ds)
    allow(db).to receive(:[]).with(:scenarios).and_return(scenarios_ds)
    allow(GemPatterns::ContentHasher).to receive(:call).and_return('abc123')
    allow(GemPatterns::ScenarioWriter).to receive_message_chain(:new, :write)
  end

  describe '#index' do
    context 'when content_hash already exists' do
      before { allow(patterns_ds).to receive(:first).and_return({ id: 1 }) }

      it 'returns :skipped' do
        expect(subject.index(entry)).to eq(:skipped)
      end
    end

    context 'when content_hash is new' do
      before do
        allow(patterns_ds).to receive(:first).and_return(nil)
        allow(patterns_ds).to receive(:returning).and_return(patterns_ds)
        allow(patterns_ds).to receive(:insert).and_return([{ id: 'uuid-1' }])
      end

      it 'returns :indexed' do
        expect(subject.index(entry)).to eq(:indexed)
      end

      it 'calls embedder with embedding text' do
        subject.index(entry)
        expect(embedder).to have_received(:call).with('Database toolkit need db')
      end
    end
  end

  describe '#reset' do
    it 'truncates both tables' do
      allow(db).to receive(:[]).with(:scenarios).and_return(scenarios_ds)
      allow(db).to receive(:[]).with(:patterns).and_return(patterns_ds)
      allow(scenarios_ds).to receive(:truncate)
      allow(patterns_ds).to receive(:truncate)

      subject.reset

      expect(scenarios_ds).to have_received(:truncate)
      expect(patterns_ds).to have_received(:truncate)
    end
  end
end

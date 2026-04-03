# frozen_string_literal: true

module GemPatterns
  class Runner
    def initialize(llm: nil, fetch: nil, store: nil, writer: nil, search: nil)
      @llm = llm || LLM.new
      @fetch = fetch || Fetch.new
      @store = store || Store.new
      @writer = writer || Writer.new
      @search = search || Search.new
      @build = Build.new
    end

    def init
      :initialized
    end

    def run(gem_names, vector: true)
      gem_names.map do |name|
        data = @fetch.call(name)
        llm_result = @llm.generate(name, data&.dig('info') || '')
        entry = @build.call(name: name, data: data, llm_result: llm_result)
        @writer.write(entry)
        result = @store.index(entry) if vector
        warn "Index failed for #{name}" if result == :error
        entry
      end
    end

    def search(query)
      @search.call(query)
    end

    def count
      @search.count
    end
  end
end

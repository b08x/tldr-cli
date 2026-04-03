# frozen_string_literal: true

require 'ruby_llm'
require 'circuit_breaker'
require_relative 'pattern_schema'

module GemPatterns
  class LLM
    MAX_RETRIES = 3
    BASE_DELAY = 1.0

    def initialize(provider: :mistral, model: nil)
      @provider = provider
      @model = model || (@provider == :openrouter ? 'mistralai/mistral-small' : 'mistral-small')
      @mutex = Mutex.new
    end

    def generate(gem_name, description, count: 5)
      ensure_configured
      prompt = "Gem: #{gem_name}\nDescription: #{description[0..500]}\nGenerate #{count} scenarios (trigger, snippet, gotchas) as JSON."
      with_circuit_breaker { with_retry { RubyLLM.chat(model: @model).with_schema(PatternSchema).ask(prompt).content } }
    rescue StandardError => e
      warn "LLM error [#{e.class}] #{gem_name}: #{e.message}"
      nil
    end

    private

    def with_circuit_breaker(&block)
      breaker = CircuitBreaker.new('llm', threshold: 3, reset_timeout: 30)
      breaker.run(&block)
    end

    def with_retry
      attempts = 0
      begin
        yield
      rescue StandardError
        attempts += 1
        raise if attempts >= MAX_RETRIES

        sleep(BASE_DELAY * (2**(attempts - 1)))
        retry
      end
    end

    def ensure_configured
      @mutex.synchronize do
        return if @configured

        RubyLLM.configure do |config|
          config.mistral_api_key = ENV['MISTRAL_API_KEY']
          config.openrouter_api_key = ENV['OPENROUTER_API_KEY']
        end
        @configured = true
      end
    end
  end
end

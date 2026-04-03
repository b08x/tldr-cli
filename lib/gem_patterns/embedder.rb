# frozen_string_literal: true

require 'informers'
require 'circuit_breaker'

module GemPatterns
  class Embedder
    MAX_RETRIES = 2
    BASE_DELAY = 0.5

    def initialize(model: 'Xenova/all-MiniLM-L6-v2')
      @model = Informers.pipeline('embedding', model)
    end

    def call(text)
      with_circuit_breaker { with_retry { @model.call(text).first } }
    rescue StandardError => e
      warn "Embed error [#{e.class}]: #{e.message}"
      [0.0] * 384
    end

    private

    def with_circuit_breaker(&block)
      breaker = CircuitBreaker.new('embedder', threshold: 3, reset_timeout: 15)
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
  end
end

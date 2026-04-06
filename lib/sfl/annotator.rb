# frozen_string_literal: true

require 'ruby_llm'
require 'circuit_breaker'
require_relative 'ideational_schema'

module SFL
  class Annotator
    MAX_RETRIES = 2
    BASE_DELAY = 0.5

    def initialize(model: nil)
      @model = model || 'mistral-small'
      @breaker = CircuitBreaker.new('sfl_annotator', threshold: 3, reset_timeout: 30)
    end

    def annotate(clause_text)
      @breaker.run do
        with_retry do
          chat = RubyLLM.chat(model: @model)
          {
            ideational: chat.with_schema(IdeationalSchema).ask(ideational_prompt(clause_text)).content,
            interpersonal: chat.with_schema(InterpersonalSchema).ask(interpersonal_prompt(clause_text)).content,
            textual: chat.with_schema(TextualSchema).ask(textual_prompt(clause_text)).content
          }
        end
      end
    rescue StandardError => e
      warn "SFL annotate error [#{e.class}]: #{e.message}"
      nil
    end

    private

    def ideational_prompt(text)
      "Analyze this clause using SFL Transitivity:\n\"#{text}\"\nIdentify process type, participants, and circumstances."
    end

    def interpersonal_prompt(text)
      "Analyze this clause using SFL Mood system:\n\"#{text}\"\nIdentify mood type, modality, subject, finite, and residue."
    end

    def textual_prompt(text)
      "Analyze this clause using SFL Theme/Rheme:\n\"#{text}\"\nIdentify theme type, theme text, and rheme text."
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

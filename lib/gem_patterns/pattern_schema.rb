# frozen_string_literal: true

require 'ruby_llm/schema'

module GemPatterns
  # Schema for pattern generation
  class PatternSchema < RubyLLM::Schema
    array :scenarios do
      object do
        string :id
        string :trigger
        string :snippet
        array :gotchas, of: :string
      end
    end
    array :failure_modes, of: :string
    object :meta do
      integer :invasiveness
      integer :coupling
      string :abstraction_leak
    end
  end
end

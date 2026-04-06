# frozen_string_literal: true

require 'ruby_llm/schema'

module SFL
  class IdeationalSchema < RubyLLM::Schema
    description 'SFL Ideational Analysis: Process, Participants, and Circumstances'

    string :process_type,
           enum: %w[material mental relational verbal behavioural existential],
           description: "Halliday's process type for this clause."

    string :process_lemma,
           description: 'Base form of the main verb.'

    array :participants, description: 'Entities directly involved in the process.' do
      object do
        string :role,
               description: 'SFL role: Actor, Goal, Senser, Phenomenon, Carrier, Attribute, Sayer.'
        string :text, description: 'Text span realizing this participant.'
      end
    end

    array :circumstances, description: 'Contextual information (time, place, manner, cause).' do
      object do
        string :type, description: 'Time, Place, Manner, Cause, Accompaniment.'
        string :text
      end
    end
  end

  class InterpersonalSchema < RubyLLM::Schema
    description 'SFL Interpersonal Analysis: Mood and Modality'

    string :mood_type,
           enum: %w[declarative interrogative imperative exclamative minor],
           description: 'Clause mood based on speech function.'

    string :modality,
           enum: %w[high medium low none],
           description: 'Degree of certainty or obligation.'

    string :subject, description: 'Grammatical subject (Mood Block).'
    string :finite, description: 'Finite operator carrying tense/polarity.'
    string :residue, description: 'Predicator + Complements + Adjuncts.'
  end

  class TextualSchema < RubyLLM::Schema
    description 'SFL Textual Analysis: Theme and Rheme'

    string :theme_type,
           enum: %w[topical interpersonal textual multiple],
           description: 'Type of Theme element.'

    string :theme, description: 'Point of departure of the message.'
    string :rheme, description: 'Development of the Theme.'
    string :cohesion_prev, description: 'Reference to preceding clause (if linked).'
  end
end

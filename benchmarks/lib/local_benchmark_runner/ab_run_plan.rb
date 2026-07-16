# frozen_string_literal: true

module LocalBenchmarkRunner
  # Balanced A/B execution order for repeated local benchmark comparisons.
  class AbRunPlan
    Step = Struct.new(:scenario, :repetition, :sequence_index, keyword_init: true)

    attr_reader :a_name, :b_name, :repetitions

    def initialize(a_name:, b_name:, repetitions:)
      raise ArgumentError, "repetitions must be positive" unless repetitions.positive?

      @a_name = a_name
      @b_name = b_name
      @repetitions = repetitions
    end

    def steps
      sequence_index = 0
      (1..repetitions).flat_map do |repetition|
        names = repetition.odd? ? [a_name, b_name] : [b_name, a_name]
        names.map do |scenario|
          sequence_index += 1
          Step.new(scenario:, repetition:, sequence_index:)
        end
      end
    end
  end
end

# frozen_string_literal: true

require_relative "../spec_helper"
require_relative "../../lib/local_benchmark_runner/ab_run_plan"

RSpec.describe LocalBenchmarkRunner::AbRunPlan do
  it "alternates which scenario runs first for each repetition" do
    plan = described_class.new(a_name: "main", b_name: "rc5", repetitions: 3)

    expect(plan.steps.map { |step| [step.scenario, step.repetition] }).to eq(
      [
        ["main", 1],
        ["rc5", 1],
        ["rc5", 2],
        ["main", 2],
        ["main", 3],
        ["rc5", 3]
      ]
    )
  end

  it "rejects non-positive repetitions" do
    expect { described_class.new(a_name: "a", b_name: "b", repetitions: 0) }
      .to raise_error(ArgumentError, /repetitions/)
  end
end

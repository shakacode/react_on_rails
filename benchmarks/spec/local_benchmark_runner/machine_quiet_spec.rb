# frozen_string_literal: true

require_relative "../spec_helper"
require_relative "../../lib/local_benchmark_runner/machine_quiet"

RSpec.describe LocalBenchmarkRunner::MachineQuiet do
  def sample(load_per_core:, cpu_percent:, top_process_percent: 0.0)
    described_class::Sample.new(
      load_per_core:,
      cpu_percent:,
      top_process_percent:,
      timestamp: Time.utc(2026, 1, 1)
    )
  end

  it "requires consecutive quiet samples before declaring the machine quiet" do
    samples = [
      sample(load_per_core: 0.10, cpu_percent: 5.0),
      sample(load_per_core: 0.90, cpu_percent: 5.0),
      sample(load_per_core: 0.10, cpu_percent: 5.0),
      sample(load_per_core: 0.10, cpu_percent: 5.0)
    ]

    gate = described_class.new(
      sampler: -> { samples.shift },
      sleeper: ->(_seconds) {},
      thresholds: described_class::Thresholds.new(
        max_load_per_core: 0.25,
        max_cpu_percent: 20.0,
        max_top_process_percent: 60.0,
        required_samples: 2,
        sample_interval: 0,
        timeout: 30
      )
    )

    result = gate.wait

    expect(result).to be_quiet
    expect(result.samples.map(&:quiet?)).to eq([true, false, true, true])
  end

  it "times out when no quiet window appears" do
    now = Time.utc(2026, 1, 1)
    sampler = lambda do
      now += 2
      sample(load_per_core: 0.90, cpu_percent: 5.0)
    end

    gate = described_class.new(
      sampler:,
      monotonic_clock: -> { now.to_f },
      sleeper: ->(_seconds) {},
      thresholds: described_class::Thresholds.new(
        max_load_per_core: 0.25,
        max_cpu_percent: 20.0,
        max_top_process_percent: 60.0,
        required_samples: 2,
        sample_interval: 0,
        timeout: 3
      )
    )

    result = gate.wait

    expect(result).not_to be_quiet
    expect(result.reason).to match(/Timed out/)
  end

  it "rejects a zero quiet-sample threshold" do
    expect { described_class::Thresholds.new(required_samples: 0) }
      .to raise_error(ArgumentError, /required_samples must be positive/)
  end
end

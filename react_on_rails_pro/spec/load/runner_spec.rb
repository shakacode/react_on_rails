# frozen_string_literal: true

require_relative "spec_helper"
require "request_result"
require "runner"

RSpec.describe RendererHarness::Runner do
  def build_config(**overrides)
    Struct.new(:requests, :duration, :concurrency, :warmup, keyword_init: true).new(
      { requests: 1, duration: nil, concurrency: 1, warmup: 0 }.merge(overrides)
    )
  end

  def build_scenario
    mutex = Mutex.new
    state = { warmup_calls: 0, perform_calls: 0 }

    Object.new.tap do |scenario|
      scenario.define_singleton_method(:warmup) do |count|
        mutex.synchronize { state[:warmup_calls] += count }
      end
      scenario.define_singleton_method(:warmup_calls) do
        mutex.synchronize { state[:warmup_calls] }
      end
      scenario.define_singleton_method(:perform_request) do
        mutex.synchronize { state[:perform_calls] += 1 }
        RendererHarness::RequestResult.new(latency_ms: 1.0, ok: true)
      end
      scenario.define_singleton_method(:perform_calls) do
        mutex.synchronize { state[:perform_calls] }
      end
    end
  end

  it "clears previous results at the start of each run" do
    runner = described_class.new(scenario: build_scenario, config: build_config(requests: 1))

    runner.run
    runner.run

    expect(runner.results.size).to eq(1)
  end

  it "starts elapsed timing after all workers finish warmup" do
    scenario = build_scenario
    runner = described_class.new(
      scenario: scenario,
      config: build_config(requests: 2, concurrency: 2, warmup: 1)
    )
    warmup_counts_at_clock_reads = []
    allow(runner).to receive(:monotonic) do
      warmup_counts_at_clock_reads << scenario.warmup_calls
      warmup_counts_at_clock_reads.length == 1 ? 10.0 : 10.5
    end

    runner.run

    expect(warmup_counts_at_clock_reads.first).to eq(2)
    expect(runner.results.size).to eq(2)
  end

  it "sets the duration deadline after warmup completes" do
    scenario = build_scenario
    runner = described_class.new(
      scenario: scenario,
      config: build_config(requests: nil, duration: 1.0, concurrency: 1, warmup: 1)
    )
    clock_values = [100.0, 100.25, 101.25, 101.5]
    warmup_counts_at_clock_reads = []
    allow(runner).to receive(:monotonic) do
      warmup_counts_at_clock_reads << scenario.warmup_calls
      clock_values.shift
    end

    runner.run

    expect(warmup_counts_at_clock_reads.first).to eq(1)
    expect(runner.results.size).to eq(1)
  end

  it "aborts before measurement if a worker fails during warmup" do
    scenario = build_scenario
    allow(scenario).to receive(:warmup).and_raise("warmup failed")
    runner = described_class.new(
      scenario: scenario,
      config: build_config(requests: 2, concurrency: 2, warmup: 1)
    )

    expect { runner.run }.to raise_error(/warmup failed/)
    expect(runner.results).to be_empty
    expect(scenario.perform_calls).to eq(0)
  end

  it "reports multiple worker errors" do
    mutex = Mutex.new
    ready = ConditionVariable.new
    entered = 0
    scenario = build_scenario
    allow(scenario).to receive(:perform_request) do
      mutex.synchronize do
        entered += 1
        ready.broadcast
        ready.wait(mutex) until entered == 2
      end
      raise "worker failure #{Thread.current.object_id}"
    end
    runner = described_class.new(
      scenario: scenario,
      config: build_config(requests: 2, concurrency: 2)
    )

    expect { runner.run }.to raise_error(described_class::WorkerErrors) do |error|
      expect(error.errors.size).to eq(2)
      expect(error.message).to include("2 worker threads failed", "worker failure")
    end
  end
end

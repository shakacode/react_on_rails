# frozen_string_literal: true

require_relative "spec_helper"
require "request_result"
require "runner"

RSpec.describe RendererHarness::Runner do
  def build_config(**overrides)
    Struct.new(:requests, :duration, :concurrency, :warmup, :start_gate_timeout, keyword_init: true).new(
      { requests: 1, duration: nil, concurrency: 1, warmup: 0, start_gate_timeout: 30.0 }.merge(overrides)
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

  it "rejects direct construction without a run mode" do
    runner = described_class.new(
      scenario: build_scenario,
      config: build_config(requests: nil, duration: nil)
    )

    expect { runner.run }.to raise_error(ArgumentError, /must provide --requests or --duration/)
  end

  it "rejects direct construction with conflicting run modes" do
    runner = described_class.new(
      scenario: build_scenario,
      config: build_config(requests: 1, duration: 1.0)
    )

    expect { runner.run }.to raise_error(ArgumentError, /mutually exclusive/)
  end

  it "starts elapsed timing after all workers finish warmup" do
    scenario = build_scenario
    runner = described_class.new(
      scenario: scenario,
      config: build_config(requests: 2, concurrency: 2, warmup: 1)
    )
    warmup_counts_at_clock_reads = []
    clock_values_after_warmup = [10.0, 10.5, 10.75, 11.0, 11.25, 11.5]
    allow(runner).to receive(:monotonic) do
      warmup_counts_at_clock_reads << scenario.warmup_calls
      scenario.warmup_calls < 2 ? 0.0 : clock_values_after_warmup.shift
    end

    runner.run

    expect(warmup_counts_at_clock_reads).to include(2)
    expect(warmup_counts_at_clock_reads.last).to eq(2)
    expect(runner.results.size).to eq(2)
  end

  it "sets the duration deadline after warmup completes" do
    scenario = build_scenario
    runner = described_class.new(
      scenario: scenario,
      config: build_config(requests: nil, duration: 1.0, concurrency: 1, warmup: 1)
    )
    main_thread = Thread.current
    main_clock_values_after_warmup = [100.0, 100.5, 101.5]
    worker_clock_values_after_warmup = [100.25, 101.25]
    warmup_counts_at_clock_reads = []
    allow(runner).to receive(:monotonic) do
      warmup_counts_at_clock_reads << scenario.warmup_calls
      if scenario.warmup_calls.zero?
        0.0
      elsif Thread.current == main_thread
        main_clock_values_after_warmup.shift
      else
        worker_clock_values_after_warmup.shift
      end
    end

    runner.run

    expect(warmup_counts_at_clock_reads).to include(1)
    expect(warmup_counts_at_clock_reads.last).to eq(1)
    expect(runner.results.size).to eq(1)
  end

  it "warns when a duration worker records zero measured requests" do
    runner = described_class.new(
      scenario: build_scenario,
      config: build_config(requests: nil, duration: 0.0, concurrency: 1)
    )
    allow(runner).to receive(:warn)

    runner.run

    expect(runner.results).to be_empty
    expect(runner).to have_received(:warn).with(/recorded 0 measured requests/)
  end

  it "allows duration runs to exceed the stuck-worker shutdown grace" do
    stub_const("#{described_class}::WORKER_JOIN_TIMEOUT_SECONDS", 0.05)
    scenario = build_scenario
    allow(scenario).to receive(:perform_request) do
      sleep 0.02
      RendererHarness::RequestResult.new(latency_ms: 20.0, ok: true)
    end
    runner = described_class.new(
      scenario: scenario,
      config: build_config(requests: nil, duration: 0.08, concurrency: 1)
    )

    expect { runner.run }.not_to raise_error
    expect(runner.results).not_to be_empty
  end

  it "allows request-count runs to exceed the stuck-worker shutdown grace" do
    stub_const("#{described_class}::WORKER_JOIN_TIMEOUT_SECONDS", 0.05)
    scenario = build_scenario
    allow(scenario).to receive(:perform_request) do
      sleep 0.03
      RendererHarness::RequestResult.new(latency_ms: 20.0, ok: true)
    end
    runner = described_class.new(scenario: scenario, config: build_config(requests: 3))

    expect { runner.run }.not_to raise_error
    expect(runner.results.size).to eq(3)
  end

  it "applies the worker join timeout as one global deadline" do
    runner = described_class.new(scenario: build_scenario, config: build_config)
    threads = Array.new(2) { fake_stuck_thread }
    allow(runner).to receive(:monotonic).and_return(10.0, 11.0)
    raised_error = nil

    begin
      runner.send(:join_threads, threads, deadline: 10.5)
    rescue described_class::WorkerErrors => e
      raised_error = e
    end

    expect(raised_error).to be_a(described_class::WorkerErrors)
    expect(raised_error.errors).to all(be_a(described_class::WorkerJoinTimeout))
    expect(threads[0].join_timeouts).to eq([0.5])
    expect(threads[1].join_timeouts).to be_empty
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

  it "times out while waiting for workers to finish warmup" do
    scenario = build_scenario
    allow(scenario).to receive(:warmup) { sleep 0.05 }
    runner = described_class.new(
      scenario: scenario,
      config: build_config(requests: 1, warmup: 1, start_gate_timeout: 0.01)
    )

    expect { runner.run }.to raise_error(
      described_class::MeasurementAborted,
      /Timed out waiting for 1 worker thread/
    )
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

  it "does not mask a worker failure when appending partial results fails" do
    scenario = build_scenario
    calls = 0
    allow(scenario).to receive(:perform_request) do
      calls += 1
      raise "worker failure" if calls == 2

      RendererHarness::RequestResult.new(latency_ms: 1.0, ok: true)
    end
    runner = described_class.new(
      scenario: scenario,
      config: build_config(requests: 2, concurrency: 1)
    )
    allow(runner).to receive(:append_results).and_raise("append failed")
    allow(runner).to receive(:warn)

    expect { runner.run }.to raise_error(/worker failure/)
    expect(runner).to have_received(:warn).with(/failed to append partial worker results/)
  end

  it "times out worker threads that never finish" do
    stub_const("#{described_class}::WORKER_JOIN_TIMEOUT_SECONDS", 0.01)
    scenario = build_scenario
    allow(scenario).to receive(:perform_request) { sleep 1 }
    runner = described_class.new(
      scenario: scenario,
      config: build_config(requests: nil, duration: 0.01)
    )

    expect { runner.run }.to raise_error(described_class::WorkerJoinTimeout, /did not finish/)
  end

  it "times out request-count workers after all requests are claimed" do
    stub_const("#{described_class}::WORKER_JOIN_TIMEOUT_SECONDS", 0.01)
    scenario = build_scenario
    allow(scenario).to receive(:perform_request) { sleep 1 }
    runner = described_class.new(scenario: scenario, config: build_config(requests: 1))

    expect { runner.run }.to raise_error(described_class::WorkerJoinTimeout, /did not finish/)
  end

  it "times out request-count workers when requests remain unclaimed" do
    stub_const("#{described_class}::WORKER_JOIN_TIMEOUT_SECONDS", 0.01)
    scenario = build_scenario
    allow(scenario).to receive(:perform_request) { sleep 1 }
    runner = described_class.new(scenario: scenario, config: build_config(requests: 2))

    expect { runner.run }.to raise_error(described_class::WorkerJoinTimeout, /did not finish/)
  end

  it "uses a fallback timeout before a request-count worker claims a request" do
    stub_const("#{described_class}::WORKER_JOIN_TIMEOUT_SECONDS", 0.01)
    runner = described_class.new(scenario: build_scenario, config: build_config(requests: 1))

    expect(runner.send(:join_count_thread, fake_stuck_thread)).to be_nil
  end

  def fake_stuck_thread
    Class.new do
      attr_reader :join_timeouts

      def initialize
        @join_timeouts = []
      end

      def join(timeout = :none)
        @join_timeouts << timeout
        nil
      end

      def kill; end
    end.new
  end
end

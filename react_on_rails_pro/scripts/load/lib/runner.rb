# frozen_string_literal: true

module RendererHarness
  class Runner
    StartGate = Struct.new(:mutex, :ready_cv, :start_cv, :ready_count, :started, :deadline, keyword_init: true)

    attr_reader :results

    def initialize(scenario:, config:)
      @scenario = scenario
      @config = config
      @results = []
      @results_mutex = Mutex.new
    end

    # Returns elapsed seconds with per-thread warmup excluded.
    def run
      @results_mutex.synchronize { @results.clear }
      gate = start_gate
      threads = build_threads(gate)
      start = release_workers_when_ready(gate)
      join_threads(threads)
      monotonic - start
    end

    private

    def build_threads(gate)
      if @config.requests
        run_by_count(gate)
      else
        run_by_duration(gate)
      end
    end

    def run_by_count(gate)
      @remaining = @config.requests
      @remaining_mutex = Mutex.new
      Array.new(@config.concurrency) do
        Thread.new do
          prepare_worker(gate)
          record(@scenario.perform_request) while claim_request
        end
      end
    end

    def claim_request
      @remaining_mutex.synchronize do
        return false if @remaining <= 0

        @remaining -= 1
        true
      end
    end

    def run_by_duration(gate)
      Array.new(@config.concurrency) do
        Thread.new do
          deadline = prepare_worker(gate)
          record(@scenario.perform_request) while monotonic < deadline
        end
      end
    end

    def prepare_worker(gate)
      warmup_error = nil
      begin
        @scenario.warmup(@config.warmup) if @config.warmup.positive?
      rescue StandardError => e
        warmup_error = e
      end

      deadline = wait_for_measurement_start(gate)
      raise warmup_error if warmup_error

      deadline
    end

    def start_gate
      StartGate.new(
        mutex: Mutex.new,
        ready_cv: ConditionVariable.new,
        start_cv: ConditionVariable.new,
        ready_count: 0,
        started: false
      )
    end

    def release_workers_when_ready(gate)
      gate.mutex.synchronize do
        gate.ready_cv.wait(gate.mutex) until gate.ready_count == @config.concurrency
        start = monotonic
        gate.deadline = start + @config.duration if @config.duration
        gate.started = true
        gate.start_cv.broadcast
        start
      end
    end

    def wait_for_measurement_start(gate)
      gate.mutex.synchronize do
        gate.ready_count += 1
        gate.ready_cv.signal
        gate.start_cv.wait(gate.mutex) until gate.started
        gate.deadline
      end
    end

    def join_threads(threads)
      errors = []
      threads.each do |thread|
        thread.value
      rescue StandardError => e
        errors << e
      end
      raise errors.first if errors.any?
    end

    def record(result)
      @results_mutex.synchronize { @results << result }
    end

    def monotonic
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end

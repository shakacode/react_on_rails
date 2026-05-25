# frozen_string_literal: true

module RendererHarness
  class Runner
    StartGate = Struct.new(:mutex, :ready_cv, :start_cv, :ready_count, :started, :aborted, :deadline,
                           keyword_init: true)
    MeasurementAborted = Class.new(StandardError)

    class WorkerErrors < StandardError
      attr_reader :errors

      def initialize(errors)
        @errors = errors
        super(build_message(errors))
        set_backtrace(errors.first.backtrace)
      end

      private

      def build_message(errors)
        header = "#{errors.size} worker threads failed"
        details = errors.map.with_index(1) do |error, index|
          "#{index}. #{error.class}: #{error.message}"
        end
        ([header] + details).join("\n")
      end
    end

    attr_reader :results, :measurement_started_at

    def initialize(scenario:, config:)
      @scenario = scenario
      @config = config
      @results = []
      @results_mutex = Mutex.new
      @measurement_started_at = nil
    end

    # Returns elapsed seconds with per-thread warmup excluded.
    def run
      @results_mutex.synchronize { @results.clear }
      @measurement_started_at = nil
      gate = start_gate
      threads = build_threads(gate)
      start = release_workers_when_ready(gate)
      join_threads(threads)
      raise MeasurementAborted, "Measurement aborted before workers started" unless start

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
        worker_thread(gate) do
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
        worker_thread(gate) do
          deadline = prepare_worker(gate)
          record(@scenario.perform_request) while monotonic < deadline
        end
      end
    end

    def prepare_worker(gate)
      @scenario.warmup(@config.warmup) if @config.warmup.positive?
      wait_for_measurement_start(gate)
    end

    def worker_thread(gate)
      Thread.new do
        Thread.current.report_on_exception = false
        yield
      rescue StandardError
        abort_measurement_start(gate) unless measurement_started?(gate)
        raise
      end
    end

    def start_gate
      StartGate.new(
        mutex: Mutex.new,
        ready_cv: ConditionVariable.new,
        start_cv: ConditionVariable.new,
        ready_count: 0,
        started: false,
        aborted: false
      )
    end

    def release_workers_when_ready(gate)
      gate.mutex.synchronize do
        gate.ready_cv.wait(gate.mutex) until gate.ready_count == @config.concurrency || gate.aborted
        return nil if gate.aborted

        start = monotonic
        @measurement_started_at = start
        gate.deadline = start + @config.duration if @config.duration
        gate.started = true
        gate.start_cv.broadcast
        start
      end
    end

    def wait_for_measurement_start(gate)
      gate.mutex.synchronize do
        raise MeasurementAborted, "Measurement aborted before this worker started" if gate.aborted

        gate.ready_count += 1
        gate.ready_cv.signal
        gate.start_cv.wait(gate.mutex) until gate.started || gate.aborted
        raise MeasurementAborted, "Measurement aborted before this worker started" if gate.aborted

        gate.deadline
      end
    end

    def abort_measurement_start(gate)
      gate.mutex.synchronize do
        gate.aborted = true
        gate.ready_cv.broadcast
        gate.start_cv.broadcast
      end
    end

    def measurement_started?(gate)
      gate.mutex.synchronize { gate.started }
    end

    def join_threads(threads)
      errors = []
      threads.each do |thread|
        thread.value
      rescue StandardError => e
        errors << e
      end

      raise_worker_errors(errors) if errors.any?
    end

    def raise_worker_errors(errors)
      actionable_errors = errors.reject { |error| error.is_a?(MeasurementAborted) }
      actionable_errors = errors if actionable_errors.empty?
      raise actionable_errors.first if actionable_errors.one?

      raise WorkerErrors, actionable_errors
    end

    def record(result)
      @results_mutex.synchronize { @results << result }
    end

    def monotonic
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end

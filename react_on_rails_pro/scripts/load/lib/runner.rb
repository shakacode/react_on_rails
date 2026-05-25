# frozen_string_literal: true

module RendererHarness
  class Runner # rubocop:disable Metrics/ClassLength
    StartGate = Struct.new(:mutex, :ready_cv, :start_cv, :ready_count, :started, :aborted, :deadline,
                           :abort_error, keyword_init: true)
    WORKER_JOIN_TIMEOUT_SECONDS = 30
    MeasurementAborted = Class.new(StandardError)
    WorkerJoinTimeout = Class.new(StandardError)

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
      @remaining = 0
      @remaining_mutex = Mutex.new
      @remaining_cv = ConditionVariable.new
      @count_join_deadline = nil
    end

    # Returns elapsed seconds with per-thread warmup excluded.
    def run
      validate_run_mode!
      @results_mutex.synchronize { @results.clear }
      @measurement_started_at = nil
      gate = start_gate
      threads = build_threads(gate)
      start = release_workers_when_ready(gate)
      join_threads(threads, deadline: worker_join_deadline(start), ignore_measurement_aborted: start.nil?)
      raise(gate.abort_error || MeasurementAborted.new("Measurement aborted before workers started")) unless start

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
      @remaining_mutex.synchronize do
        @remaining = @config.requests
        @count_join_deadline = nil
      end
      Array.new(@config.concurrency) do
        worker_thread(gate) do |worker_results|
          # Count-based runs stop via claim_request; every claim refreshes the
          # stuck-worker join grace so long runs can continue while hung
          # requests still time out.
          prepare_worker(gate)
          worker_results << @scenario.perform_request while claim_request
        end
      end
    end

    def claim_request
      @remaining_mutex.synchronize do
        return false if @remaining <= 0

        @remaining -= 1
        @count_join_deadline = monotonic + WORKER_JOIN_TIMEOUT_SECONDS
        @remaining_cv.broadcast
        true
      end
    end

    def run_by_duration(gate)
      Array.new(@config.concurrency) do
        worker_thread(gate) do |worker_results|
          deadline = prepare_worker(gate)
          worker_results << @scenario.perform_request while monotonic < deadline
          warn_zero_duration_results(deadline) if worker_results.empty?
        end
      end
    end

    def prepare_worker(gate)
      @scenario.warmup(@config.warmup) if @config.warmup.positive?
      wait_for_measurement_start(gate)
    end

    def worker_thread(gate)
      Thread.new do
        # join_threads reports worker failures once; disabling thread exception
        # reporting avoids duplicate stderr noise without hiding failures.
        Thread.current.report_on_exception = false
        worker_results = []
        worker_error = nil
        begin
          yield worker_results
        rescue StandardError => e
          worker_error = e
          raise
        ensure
          append_worker_results(worker_results, worker_error)
          notify_count_join_waiters
        end
      rescue StandardError => e
        abort_measurement_start(gate, e) unless measurement_started?(gate)
        raise
      end
    end

    def append_worker_results(worker_results, worker_error)
      return unless worker_results.any?

      append_results(worker_results)
    rescue StandardError => e
      raise unless worker_error

      warn(
        "RendererHarness::Runner: failed to append partial worker results after worker failure: " \
        "#{e.class}: #{e.message}"
      )
    end

    def warn_zero_duration_results(deadline)
      warn(
        "RendererHarness::Runner: duration worker #{Thread.current.object_id} recorded 0 measured requests " \
        "because the measurement deadline (#{format('%.3f', deadline)}) had already passed"
      )
    end

    def start_gate
      StartGate.new(
        mutex: Mutex.new,
        ready_cv: ConditionVariable.new,
        start_cv: ConditionVariable.new,
        ready_count: 0,
        started: false,
        aborted: false,
        deadline: nil,
        abort_error: nil
      )
    end

    def release_workers_when_ready(gate)
      gate.mutex.synchronize do
        wait_for_ready_workers(gate)
        return nil if gate.aborted

        release_measurement_start(gate)
      end
    end

    def wait_for_ready_workers(gate)
      deadline = monotonic + @config.start_gate_timeout
      until gate.ready_count == @config.concurrency || gate.aborted
        remaining = deadline - monotonic
        return abort_start_gate_timeout(gate) if remaining <= 0

        gate.ready_cv.wait(gate.mutex, remaining)
      end
    end

    def abort_start_gate_timeout(gate)
      gate.aborted = true
      gate.abort_error ||= MeasurementAborted.new(
        "Timed out waiting for #{@config.concurrency - gate.ready_count} worker thread(s) to finish warmup"
      )
      gate.ready_cv.broadcast
      gate.start_cv.broadcast
    end

    def release_measurement_start(gate)
      start = monotonic
      @measurement_started_at = start
      gate.deadline = start + @config.duration if @config.duration
      gate.started = true
      gate.start_cv.broadcast
      start
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

    def abort_measurement_start(gate, error = nil)
      gate.mutex.synchronize do
        gate.aborted = true
        gate.abort_error ||= error
        gate.ready_cv.broadcast
        gate.start_cv.broadcast
      end
    end

    def measurement_started?(gate)
      gate.mutex.synchronize { gate.started }
    end

    def validate_run_mode!
      raise ArgumentError, "must provide --requests or --duration" if @config.requests.nil? && @config.duration.nil?

      raise ArgumentError, "--requests and --duration are mutually exclusive" if @config.requests && @config.duration
    end

    def worker_join_deadline(measurement_start)
      return monotonic + WORKER_JOIN_TIMEOUT_SECONDS unless measurement_start
      return count_join_deadline if @config.requests

      measurement_start + @config.duration + WORKER_JOIN_TIMEOUT_SECONDS
    end

    def count_join_deadline
      :after_requests_claimed
    end

    def join_threads(threads, deadline:, ignore_measurement_aborted: false)
      errors = []
      threads.each do |thread|
        unless join_thread(thread, deadline)
          # Thread#kill is acceptable here only because the CLI exits right
          # after reporting worker timeouts. Do not reuse this pattern in a
          # long-lived server or embedded harness.
          thread.kill
          errors << WorkerJoinTimeout.new(
            "worker thread did not finish before the global join deadline"
          )
          next
        end

        thread.value
      rescue StandardError => e
        errors << e
      end

      raise_worker_errors(errors, ignore_measurement_aborted: ignore_measurement_aborted) if errors.any?
    end

    def join_thread(thread, deadline)
      return join_count_thread(thread) if deadline == count_join_deadline
      return thread.join unless deadline

      remaining = deadline - monotonic
      return nil unless remaining.positive?

      thread.join(remaining)
    end

    def join_count_thread(thread)
      @remaining_mutex.synchronize do
        loop do
          # Non-blocking join while holding @remaining_mutex is intentional;
          # @remaining_cv.wait releases it so workers can still claim requests.
          joined_thread = thread.join(0)
          return joined_thread if joined_thread

          deadline = @count_join_deadline
          unless deadline
            @remaining_cv.wait(@remaining_mutex)
            next
          end

          remaining = deadline - monotonic
          return nil unless remaining.positive?

          @remaining_cv.wait(@remaining_mutex, remaining)
        end
      end
    end

    def raise_worker_errors(errors, ignore_measurement_aborted:)
      actionable_errors = if ignore_measurement_aborted
                            errors.reject { |error| error.is_a?(MeasurementAborted) }
                          else
                            errors
                          end
      return if actionable_errors.empty?

      raise actionable_errors.first if actionable_errors.one?

      raise WorkerErrors, actionable_errors
    end

    def append_results(worker_results)
      @results_mutex.synchronize { @results.concat(worker_results) }
    end

    def notify_count_join_waiters
      return unless @config.requests

      @remaining_mutex.synchronize { @remaining_cv.broadcast }
    end

    def monotonic
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end

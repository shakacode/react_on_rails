# frozen_string_literal: true

module RendererHarness
  class Runner
    attr_reader :results

    def initialize(scenario:, config:)
      @scenario = scenario
      @config = config
      @results = []
      @results_mutex = Mutex.new
    end

    # Returns elapsed seconds.
    def run
      start = monotonic
      threads = build_threads
      threads.each(&:join)
      monotonic - start
    end

    private

    def build_threads
      if @config.requests
        run_by_count
      else
        run_by_duration
      end
    end

    def run_by_count
      @remaining = @config.requests
      @remaining_mutex = Mutex.new
      Array.new(@config.concurrency) do
        Thread.new do
          @scenario.warmup(@config.warmup) if @config.warmup.positive?
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

    def run_by_duration
      deadline = monotonic + @config.duration
      Array.new(@config.concurrency) do
        Thread.new do
          @scenario.warmup(@config.warmup) if @config.warmup.positive?
          record(@scenario.perform_request) while monotonic < deadline
        end
      end
    end

    def record(result)
      @results_mutex.synchronize { @results << result }
    end

    def monotonic
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end

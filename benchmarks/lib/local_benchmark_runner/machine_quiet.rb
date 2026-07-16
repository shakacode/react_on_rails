# frozen_string_literal: true

module LocalBenchmarkRunner
  # Waits for a quiet local-machine window before a benchmark run.
  #
  # The gate intentionally uses cheap, cross-platform-ish signals available on a
  # developer Mac or Linux host: one-minute load average per CPU, aggregate process
  # CPU as a percentage of total machine capacity, and the hottest single process.
  class MachineQuiet
    Thresholds = Struct.new(
      :max_load_per_core,
      :max_cpu_percent,
      :max_top_process_percent,
      :required_samples,
      :sample_interval,
      :timeout,
      keyword_init: true
    ) do
      def initialize(
        max_load_per_core: 0.25,
        max_cpu_percent: 20.0,
        max_top_process_percent: 75.0,
        required_samples: 6,
        sample_interval: 10,
        timeout: 21_600
      )
        raise ArgumentError, "required_samples must be positive" unless required_samples.positive?

        super
      end
    end

    Sample = Struct.new(
      :load_per_core,
      :cpu_percent,
      :top_process_percent,
      :timestamp,
      :quiet,
      :reason,
      keyword_init: true
    ) do
      def quiet? = quiet == true

      def evaluate(thresholds)
        failures = []
        if load_per_core > thresholds.max_load_per_core
          failures << format(
            "load/core %<actual>.2f > %<max>.2f",
            actual: load_per_core,
            max: thresholds.max_load_per_core
          )
        end
        if cpu_percent > thresholds.max_cpu_percent
          failures << format(
            "cpu %<actual>.1f%% > %<max>.1f%%",
            actual: cpu_percent,
            max: thresholds.max_cpu_percent
          )
        end
        if top_process_percent > thresholds.max_top_process_percent
          failures << format(
            "top process %<actual>.1f%% > %<max>.1f%%",
            actual: top_process_percent,
            max: thresholds.max_top_process_percent
          )
        end

        self.class.new(
          load_per_core:,
          cpu_percent:,
          top_process_percent:,
          timestamp:,
          quiet: failures.empty?,
          reason: failures.empty? ? "quiet" : failures.join(", ")
        )
      end

      def summary
        format(
          "load/core=%<load>.2f cpu=%<cpu>.1f%% top=%<top>.1f%% %<status>s",
          load: load_per_core,
          cpu: cpu_percent,
          top: top_process_percent,
          status: quiet? ? "quiet" : "noisy: #{reason}"
        )
      end
    end

    Result = Struct.new(:quiet, :reason, :samples, keyword_init: true) do
      def quiet? = quiet == true
    end

    def self.current_sample
      cpu_count = machine_cpu_count
      Sample.new(
        load_per_core: one_minute_load_average / cpu_count,
        cpu_percent: aggregate_process_cpu_percent / cpu_count,
        top_process_percent: top_process_cpu_percent,
        timestamp: Time.now
      )
    end

    def self.machine_cpu_count
      count = Integer(`getconf _NPROCESSORS_ONLN 2>/dev/null`.strip, exception: false)
      count&.positive? ? count : 1
    end

    def self.one_minute_load_average
      raw = if File.exist?("/proc/loadavg")
              File.read("/proc/loadavg")
            else
              `sysctl -n vm.loadavg 2>/dev/null`
            end
      Float(raw[/\d+(?:\.\d+)?/] || 0.0)
    rescue StandardError
      0.0
    end

    def self.aggregate_process_cpu_percent
      ps_cpu_values.sum
    end

    def self.top_process_cpu_percent
      ps_cpu_values.max || 0.0
    end

    def self.ps_cpu_values
      `ps -A -o %cpu= 2>/dev/null`.lines.filter_map { |line| Float(line.strip, exception: false) }
    end

    def initialize(
      sampler: -> { self.class.current_sample },
      thresholds: Thresholds.new,
      monotonic_clock: -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) },
      sleeper: ->(seconds) { sleep seconds }
    )
      @sampler = sampler
      @thresholds = thresholds
      @monotonic_clock = monotonic_clock
      @sleeper = sleeper
    end

    def wait
      samples = []
      consecutive_quiet = 0
      deadline = @monotonic_clock.call + @thresholds.timeout

      loop do
        sample = @sampler.call.evaluate(@thresholds)
        samples << sample
        consecutive_quiet = sample.quiet? ? consecutive_quiet + 1 : 0

        if consecutive_quiet >= @thresholds.required_samples
          return Result.new(quiet: true, reason: "quiet window reached", samples:)
        end

        break if @monotonic_clock.call >= deadline

        @sleeper.call(@thresholds.sample_interval)
      end

      Result.new(
        quiet: false,
        reason: "Timed out waiting for #{@thresholds.required_samples} consecutive quiet samples",
        samples:
      )
    end
  end
end

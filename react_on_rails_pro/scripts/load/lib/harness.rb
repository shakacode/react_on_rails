# frozen_string_literal: true

require "fileutils"
require "time"
require "socket"
require "timeout"
require_relative "config"
require_relative "request_result"
require_relative "metrics"
require_relative "memory_sampler"
require_relative "runner"
require_relative "reporters/json_reporter"
require_relative "reporters/csv_reporter"
require_relative "reporters/terminal_reporter"
require_relative "scenario_registry"

module RendererHarness
  UserError = Class.new(StandardError)
  TRANSPORT_ENV = "REACT_ON_RAILS_RENDERER_TRANSPORT"
  DEFAULT_TRANSPORT = "httpx"

  class Harness
    UPLOAD_ASSETS_TIMEOUT_SECONDS = 10

    def initialize(config)
      @config = config
      @output_dir = config.output_dir || default_output_dir
    end

    def run
      FileUtils.mkdir_p(@output_dir)
      scenario_class = RendererHarness::SCENARIO_REGISTRY.fetch(@config.scenario)
      scenario = scenario_class.new(@config)

      sampler = MemorySampler.new(pids: { rails: Process.pid, renderer: @config.renderer_pid })
      runner = Runner.new(scenario: scenario, config: @config)

      begin
        # Upload the server bundle to the renderer before running so that the
        # first real request does not get a 410 Send-Bundle handshake response.
        upload_assets!
        sampler.start_background(interval_seconds: @config.mem_interval)
        elapsed = runner.run
      ensure
        begin
          sampler.stop_background
        ensure
          scenario.cleanup
        end
      end

      memory_rows = sampler.rows
      summary = build_summary(
        runner.results,
        memory_rows,
        elapsed,
        measurement_start_offset(sampler, runner)
      )
      write_outputs(summary, runner.results, memory_rows)
      Reporters::TerminalReporter.print($stdout, summary)
      summary
    end

    private

    def upload_assets!
      Timeout.timeout(UPLOAD_ASSETS_TIMEOUT_SECONDS) do
        ReactOnRailsPro::Request.upload_assets
      end
    rescue Timeout::Error
      raise UserError,
            "bundle upload timed out after #{UPLOAD_ASSETS_TIMEOUT_SECONDS}s - is the node renderer responsive?"
    rescue StandardError => e
      raise UserError, "bundle upload failed - is the node renderer running? (#{e.class}: #{e.message})"
    end

    def build_summary(results, mem_rows, elapsed, memory_offset_seconds = 0.0)
      lat = Metrics.summarize_latencies(results)
      measured_mem_rows = measured_memory_rows(mem_rows, memory_offset_seconds)
      rails_series = build_rails_series(measured_mem_rows)
      renderer_series = build_renderer_series(measured_mem_rows)

      {
        scenario: @config.scenario,
        transport: ENV.fetch(TRANSPORT_ENV, DEFAULT_TRANSPORT),
        concurrency: @config.concurrency,
        mix: @config.mix,
        warmup: @config.warmup,
        start_gate_timeout: @config.start_gate_timeout,
        elapsed_seconds: elapsed,
        ruby_version: RUBY_VERSION,
        hostname: Socket.gethostname,
        requests: build_requests_block(lat, elapsed),
        latency_ms: lat.slice(:p50, :p90, :p95, :p99, :p99_9, :max, :mean),
        memory: build_memory_block(rails_series, renderer_series),
        output_dir: @output_dir
      }
    end

    def measurement_start_offset(sampler, runner)
      return 0.0 unless runner.measurement_started_at

      [runner.measurement_started_at - sampler.start_time, 0.0].max
    end

    def measured_memory_rows(mem_rows, offset_seconds)
      mem_rows.filter_map do |row|
        t_seconds = row[:t_seconds].to_f
        next if t_seconds < offset_seconds

        row.merge(t_seconds: t_seconds - offset_seconds)
      end
    end

    def build_rails_series(mem_rows)
      build_rss_series(mem_rows, :rails_rss_kb, "Rails")
    end

    def build_renderer_series(mem_rows)
      build_rss_series(mem_rows.select { |r| r.key?(:renderer_rss_kb) }, :renderer_rss_kb, "Renderer")
    end

    def build_rss_series(rows, rss_key, label)
      valid, dropped = rows.partition { |r| !r[rss_key].nil? }
      warn "MemorySampler: #{dropped.size} #{label} RSS samples missing (ps failed?)" if dropped.any?
      nonzero, zero = valid.partition { |r| !r[rss_key].to_f.zero? }
      warn "MemorySampler: #{zero.size} #{label} RSS samples were zero (ps parse anomaly?)" if zero.any?
      nonzero.map { |r| [r[:t_seconds].to_f, r[rss_key].to_f] }
    end

    def build_requests_block(lat, elapsed)
      {
        count: lat[:count],
        failures: lat[:failures],
        rps: Metrics.rps(count: lat[:count], elapsed_seconds: elapsed)
      }
    end

    def build_memory_block(rails_series, renderer_series)
      {
        rails_slope_mb_per_min: Metrics.slope_mb_per_min(rails_series),
        renderer_slope_mb_per_min: renderer_series.empty? ? nil : Metrics.slope_mb_per_min(renderer_series)
      }
    end

    def write_outputs(summary, results, mem_rows)
      Reporters::JsonReporter.write(File.join(@output_dir, "summary.json"), summary)
      Reporters::CsvReporter.write_latency(File.join(@output_dir, "latency.csv"), results)
      Reporters::CsvReporter.write_memory(File.join(@output_dir, "memory.csv"), mem_rows)
    end

    def default_output_dir
      ts = Time.now.utc.strftime("%Y-%m-%dT%H-%M-%SZ")
      File.join(default_output_root, ts)
    end

    def default_output_root
      app_root = if defined?(Rails) && Rails.respond_to?(:root)
                   Rails.root
                 else
                   Dir.pwd
                 end
      File.join(app_root.to_s, "tmp", "load-tests")
    end
  end
end

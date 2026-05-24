# frozen_string_literal: true

require "fileutils"
require "time"
require "socket"
require_relative "config"
require_relative "request_result"
require_relative "metrics"
require_relative "memory_sampler"
require_relative "runner"
require_relative "reporters/json_reporter"
require_relative "reporters/csv_reporter"
require_relative "reporters/terminal_reporter"
require_relative "scenarios/standard_render"
require_relative "scenarios/streaming_render"
require_relative "scenarios/incremental_async"

module RendererHarness
  class Harness
    SCENARIO_REGISTRY = {
      "standard_render" => Scenarios::StandardRender,
      "streaming_render" => Scenarios::StreamingRender,
      "incremental_async" => Scenarios::IncrementalAsync
    }.freeze

    def initialize(config)
      @config = config
      @output_dir = config.output_dir || default_output_dir
    end

    def run
      FileUtils.mkdir_p(@output_dir)
      scenario_class = SCENARIO_REGISTRY.fetch(@config.scenario)
      scenario = scenario_class.new(@config)

      # Upload the server bundle to the renderer before running so that the
      # first real request does not get a 410 Send-Bundle handshake response.
      ReactOnRailsPro::Request.upload_assets

      sampler = MemorySampler.new(pids: { rails: Process.pid, renderer: @config.renderer_pid })
      sampler.start_background(interval_seconds: @config.mem_interval)

      runner = Runner.new(scenario: scenario, config: @config)
      elapsed = runner.run

      sampler.stop_background
      scenario.cleanup

      summary = build_summary(runner.results, sampler.rows, elapsed)
      write_outputs(summary, runner.results, sampler.rows)
      Reporters::TerminalReporter.print($stdout, summary)
      summary
    end

    private

    def build_summary(results, mem_rows, elapsed)
      lat = Metrics.summarize_latencies(results)
      rails_series = build_rails_series(mem_rows)
      renderer_series = build_renderer_series(mem_rows)

      {
        scenario: @config.scenario,
        transport: ENV.fetch(ReactOnRailsPro::RENDERER_TRANSPORT_ENV, ReactOnRailsPro::DEFAULT_RENDERER_TRANSPORT),
        concurrency: @config.concurrency,
        mix: @config.mix,
        warmup: @config.warmup,
        elapsed_seconds: elapsed,
        ruby_version: RUBY_VERSION,
        hostname: Socket.gethostname,
        requests: build_requests_block(lat, elapsed),
        latency_ms: lat.slice(:p50, :p90, :p95, :p99, :p99_9, :max, :mean),
        memory: build_memory_block(rails_series, renderer_series),
        output_dir: @output_dir
      }
    end

    def build_rails_series(mem_rows)
      mem_rows.map { |r| [r[:t_seconds].to_f, r[:rails_rss_kb].to_f] }.reject { |_, v| v.zero? }
    end

    def build_renderer_series(mem_rows)
      mem_rows.map { |r| [r[:t_seconds].to_f, (r[:renderer_rss_kb] || 0).to_f] }.reject { |_, v| v.zero? }
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
      File.join("tmp", "load-tests", ts)
    end
  end
end

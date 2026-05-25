# frozen_string_literal: true

require "optparse"
require_relative "scenario_registry"

module RendererHarness
  Config = Struct.new(
    :scenario,
    :requests,
    :duration,
    :concurrency,
    :warmup,
    :mix,
    :increments,
    :mem_interval,
    :start_gate_timeout,
    :renderer_pid,
    :output_dir,
    :smoke,
    keyword_init: true
  ) do
    def self.parse(argv)
      opts = {
        scenario: "standard_render",
        requests: nil,
        duration: nil,
        concurrency: 1,
        warmup: 5,
        mix: "small",
        increments: 5,
        mem_interval: 1.0,
        start_gate_timeout: default_start_gate_timeout_seconds,
        renderer_pid: nil,
        output_dir: nil,
        smoke: false,
        scenario_explicit: false
      }
      build_parser(opts).parse!(argv)
      apply_smoke_preset!(opts) if opts[:smoke]
      opts.delete(:scenario_explicit)
      validate!(opts)
      new(**opts).freeze
    end

    def self.build_parser(opts)
      OptionParser.new do |o|
        o.banner = "Usage: renderer_harness [options]"
        add_primary_flags(o, opts)
        add_secondary_flags(o, opts)
      end
    end

    def self.add_primary_flags(opt_parser, opts)
      opt_parser.on("--scenario NAME", String) do |v|
        opts[:scenario] = v
        opts[:scenario_explicit] = true
      end
      opt_parser.on("--requests N", Integer) { |v| opts[:requests] = v }
      opt_parser.on("--duration SECONDS", Float) { |v| opts[:duration] = v }
      opt_parser.on("--concurrency N", Integer) { |v| opts[:concurrency] = v }
      opt_parser.on("--warmup N", Integer, "Warmup requests per thread (default: 5)") do |v|
        opts[:warmup] = v
      end
      opt_parser.on("--mix MIX", %w[small medium large]) { |v| opts[:mix] = v }
    end

    def self.add_secondary_flags(opt_parser, opts)
      opt_parser.on("--increments N", Integer) { |v| opts[:increments] = v }
      opt_parser.on("--mem-interval SECONDS", Float) { |v| opts[:mem_interval] = v }
      opt_parser.on(
        "--start-gate-timeout SECONDS",
        Float,
        "Seconds to wait for worker warmup before aborting (default: #{default_start_gate_timeout_seconds.to_i})"
      ) { |v| opts[:start_gate_timeout] = v }
      opt_parser.on("--renderer-pid PID", Integer) { |v| opts[:renderer_pid] = v }
      opt_parser.on("--output-dir PATH", String) { |v| opts[:output_dir] = v }
      opt_parser.on("--smoke") { opts[:smoke] = true }
      opt_parser.on("-h", "--help") do
        puts opt_parser
        exit 0
      end
    end

    def self.apply_smoke_preset!(opts)
      if opts[:scenario_explicit] && opts[:scenario] != "standard_render"
        warn "renderer-harness: --smoke overrides --scenario #{opts[:scenario]} with standard_render"
      end
      opts[:scenario] = "standard_render"
      opts[:requests] = 10
      opts[:duration] = nil
      opts[:concurrency] = 1
      opts[:warmup] = 0
    end

    def self.validate!(opts)
      validate_scenario!(opts[:scenario])
      validate_run_mode!(opts)
      validate_numeric_options!(opts)
    end

    def self.validate_scenario!(scenario)
      return if RendererHarness::SCENARIO_REGISTRY.key?(scenario)

      raise ArgumentError, "unknown scenario: #{scenario}"
    end

    def self.validate_run_mode!(opts)
      if opts.values_at(:requests, :duration).all?(&:nil?)
        raise ArgumentError, "must provide --requests or --duration (or --smoke)"
      end
      raise ArgumentError, "--requests and --duration are mutually exclusive" if opts[:requests] && opts[:duration]
    end

    def self.validate_numeric_options!(opts)
      raise ArgumentError, "--requests must be >= 1" if opts[:requests] && opts[:requests] < 1

      validate_positive_option!("--duration", opts[:duration])
      raise ArgumentError, "--concurrency must be >= 1" if opts[:concurrency] < 1
      raise ArgumentError, "--warmup must be >= 0" if opts[:warmup].negative?

      validate_positive_option!("--mem-interval", opts[:mem_interval])
      validate_positive_option!("--start-gate-timeout", opts[:start_gate_timeout])
    end

    def self.validate_positive_option!(flag, value)
      return if value.nil? || value.positive?

      raise ArgumentError, "#{flag} must be > 0"
    end

    def self.default_start_gate_timeout_seconds
      30.0
    end

    private_class_method :build_parser, :add_primary_flags, :add_secondary_flags,
                         :apply_smoke_preset!, :validate!,
                         :validate_scenario!, :validate_run_mode!, :validate_numeric_options!,
                         :validate_positive_option!, :default_start_gate_timeout_seconds
  end
end

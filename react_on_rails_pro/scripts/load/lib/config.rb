# frozen_string_literal: true

require "optparse"

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
        renderer_pid: nil,
        output_dir: nil,
        smoke: false
      }
      build_parser(opts).parse!(argv)
      apply_smoke_preset!(opts) if opts[:smoke]
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
      opt_parser.on("--scenario NAME", String) { |v| opts[:scenario] = v }
      opt_parser.on("--requests N", Integer) { |v| opts[:requests] = v }
      opt_parser.on("--duration SECONDS", Integer) { |v| opts[:duration] = v }
      opt_parser.on("--concurrency N", Integer) { |v| opts[:concurrency] = v }
      opt_parser.on("--warmup N", Integer) { |v| opts[:warmup] = v }
      opt_parser.on("--mix MIX", %w[small medium large]) { |v| opts[:mix] = v }
    end

    def self.add_secondary_flags(opt_parser, opts)
      opt_parser.on("--increments N", Integer) { |v| opts[:increments] = v }
      opt_parser.on("--mem-interval SECONDS", Float) { |v| opts[:mem_interval] = v }
      opt_parser.on("--renderer-pid PID", Integer) { |v| opts[:renderer_pid] = v }
      opt_parser.on("--output-dir PATH", String) { |v| opts[:output_dir] = v }
      opt_parser.on("--smoke") { opts[:smoke] = true }
      opt_parser.on("-h", "--help") do
        puts opt_parser
        exit 0
      end
    end

    def self.apply_smoke_preset!(opts)
      opts[:scenario] = "standard_render"
      opts[:requests] = 10
      opts[:concurrency] = 1
      opts[:warmup] = 0
    end

    def self.validate!(opts)
      unless %w[standard_render streaming_render incremental_async].include?(opts[:scenario])
        raise ArgumentError, "unknown scenario: #{opts[:scenario]}"
      end
      if opts[:requests].nil? && opts[:duration].nil?
        raise ArgumentError, "must provide --requests or --duration (or --smoke)"
      end
      raise ArgumentError, "--requests and --duration are mutually exclusive" if opts[:requests] && opts[:duration]
      raise ArgumentError, "--concurrency must be >= 1" if opts[:concurrency] < 1
    end
  end
end

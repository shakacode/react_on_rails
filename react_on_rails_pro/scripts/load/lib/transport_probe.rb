# frozen_string_literal: true

require "async"
require "async/http"
require "async/http/protocol/http2"
require "fileutils"
require "json"
require "open3"
require "optparse"
require "protocol/http/headers"
require "securerandom"
require "tmpdir"
require "timeout"
require_relative "metrics"

begin
  require "io/endpoint/unix_endpoint"
rescue LoadError
  # The parser still works without UDS support, but live native_uds runs will
  # fail with a setup error instead of silently falling back to TCP.
end

module RendererHarness
  module TransportProbe
    UserError = Class.new(StandardError)

    DEFAULT_SCENARIOS = %w[fastify_tcp native_tcp native_uds].freeze
    PROBE_CASES = {
      "small_unary" => { path: "/probe/unary" },
      "stream_16kb" => { path: "/probe/stream" }
    }.freeze

    Config = Struct.new(
      :requests,
      :warmup,
      :body_bytes,
      :stream_bytes,
      :scenarios,
      :node_bin,
      :server_script,
      :socket_path,
      :startup_timeout,
      :output_dir,
      keyword_init: true
    ) do
      def self.parse(argv) # rubocop:disable Metrics/AbcSize
        opts = defaults
        OptionParser.new do |parser|
          parser.banner = "Usage: transport_probe [options]"
          parser.on("--requests N", Integer) { |v| opts[:requests] = v }
          parser.on("--warmup N", Integer) { |v| opts[:warmup] = v }
          parser.on("--body-bytes N", Integer) { |v| opts[:body_bytes] = v }
          parser.on("--stream-bytes N", Integer) { |v| opts[:stream_bytes] = v }
          parser.on("--scenarios LIST", String) { |v| opts[:scenarios] = parse_scenarios(v) }
          parser.on("--skip-uds") { opts[:skip_uds] = true }
          parser.on("--node-bin PATH", String) { |v| opts[:node_bin] = v }
          parser.on("--server-script PATH", String) { |v| opts[:server_script] = v }
          parser.on("--socket-path PATH", String) { |v| opts[:socket_path] = v }
          parser.on("--startup-timeout SECONDS", Float) { |v| opts[:startup_timeout] = v }
          parser.on("--output-dir PATH", String) { |v| opts[:output_dir] = v }
          parser.on("-h", "--help") do
            puts parser
            exit 0
          end
        end.parse!(argv)

        opts[:scenarios] -= ["native_uds"] if opts.delete(:skip_uds)
        validate!(opts)
        new(**opts).freeze
      end

      def self.defaults
        {
          requests: 3_000,
          warmup: 300,
          body_bytes: 4_096,
          stream_bytes: 16_384,
          scenarios: DEFAULT_SCENARIOS.dup,
          node_bin: ENV.fetch("NODE_BIN", "node"),
          server_script: default_server_script,
          socket_path: default_socket_path,
          startup_timeout: 10.0,
          output_dir: nil
        }
      end

      def self.parse_scenarios(value)
        value.split(",").map(&:strip).reject(&:empty?)
      end

      def self.validate!(opts)
        validate_positive_integer!("--requests", opts[:requests])
        validate_non_negative_integer!("--warmup", opts[:warmup])
        validate_positive_integer!("--body-bytes", opts[:body_bytes])
        validate_positive_integer!("--stream-bytes", opts[:stream_bytes])
        validate_positive_float!("--startup-timeout", opts[:startup_timeout])
        raise ArgumentError, "--scenarios must not be empty" if opts[:scenarios].empty?

        unknown = opts[:scenarios] - DEFAULT_SCENARIOS
        raise ArgumentError, "unknown scenario(s): #{unknown.join(', ')}" if unknown.any?
      end

      def self.validate_positive_integer!(flag, value)
        return if value.is_a?(Integer) && value.positive?

        raise ArgumentError, "#{flag} must be >= 1"
      end

      def self.validate_non_negative_integer!(flag, value)
        return if value.is_a?(Integer) && value >= 0

        raise ArgumentError, "#{flag} must be >= 0"
      end

      def self.validate_positive_float!(flag, value)
        return if value.to_f.positive?

        raise ArgumentError, "#{flag} must be > 0"
      end

      def self.default_server_script
        File.expand_path("../transport_probe_server.mjs", __dir__)
      end

      def self.default_socket_path
        File.join(Dir.tmpdir, "ror-transport-probe-#{Process.pid}-#{SecureRandom.hex(4)}.sock")
      end

      private_class_method :defaults, :parse_scenarios, :validate!,
                           :validate_positive_integer!, :validate_non_negative_integer!,
                           :validate_positive_float!, :default_server_script,
                           :default_socket_path
    end

    class Runner # rubocop:disable Metrics/ClassLength
      def initialize(config)
        @config = config
        @server = nil
      end

      def run
        raise UserError, "native_uds requires io-endpoint Unix support" if uds_requested_without_support?

        @server = NodeServer.start(@config)
        results = selected_endpoints.to_h do |endpoint|
          [endpoint.fetch("name"), run_endpoint(endpoint)]
        end
        summary = build_summary(results)
        write_summary(summary)
        print_summary(summary)
        summary
      ensure
        @server&.stop
      end

      private

      def uds_requested_without_support?
        @config.scenarios.include?("native_uds") && !(defined?(IO::Endpoint) && IO::Endpoint.respond_to?(:unix))
      end

      def selected_endpoints
        @server.endpoints.select { |endpoint| @config.scenarios.include?(endpoint.fetch("name")) }
      end

      def run_endpoint(endpoint)
        PROBE_CASES.transform_values do |probe_case|
          run_probe_case(endpoint, probe_case.fetch(:path))
        end
      end

      def run_probe_case(endpoint, path)
        samples = []
        failures = 0
        elapsed = with_client(endpoint) do |client|
          body = "x" * @config.body_bytes
          @config.warmup.times do
            perform_request(client, path, body)
          rescue StandardError => e
            raise UserError, "warmup request failed for #{endpoint.fetch('name')} #{path}: #{e.message}"
          end

          start = monotonic
          @config.requests.times do
            samples << measure_ms { perform_request(client, path, body) }
          rescue StandardError
            failures += 1
          end
          monotonic - start
        end

        summarize(samples, failures:, elapsed:)
      end

      def with_client(endpoint, &block)
        endpoint_obj, options = client_options(endpoint)
        Sync do
          Async::HTTP::Client.open(endpoint_obj, **options) do |client|
            # rubocop:disable Performance/RedundantBlockCall
            block.call(client)
            # rubocop:enable Performance/RedundantBlockCall
          end
        end
      end

      def client_options(endpoint)
        if endpoint.fetch("kind") == "uds"
          [
            IO::Endpoint.unix(endpoint.fetch("socketPath")),
            {
              protocol: Async::HTTP::Protocol::HTTP2,
              scheme: endpoint.fetch("scheme"),
              authority: endpoint.fetch("authority"),
              retries: 0
            }
          ]
        else
          [
            Async::HTTP::Endpoint.parse(endpoint.fetch("origin"), protocol: Async::HTTP::Protocol::HTTP2),
            { protocol: Async::HTTP::Protocol::HTTP2, retries: 0 }
          ]
        end
      end

      def perform_request(client, path, body)
        response = client.post(
          path,
          headers: Protocol::HTTP::Headers[[["content-type", "application/octet-stream"]]],
          body:
        )
        bytes = 0
        response.body&.each { |chunk| bytes += chunk.bytesize }
        raise "HTTP #{response.status}" unless response.status == 200

        bytes
      ensure
        response&.body&.close
      end

      def measure_ms
        start = monotonic
        yield
        (monotonic - start) * 1000.0
      end

      def monotonic
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end

      def summarize(samples, failures:, elapsed:)
        {
          requests: samples.length + failures,
          failures:,
          rps: Metrics.rps(count: samples.length, elapsed_seconds: elapsed),
          latency_ms: {
            p50: Metrics.percentile(samples, 50),
            p95: Metrics.percentile(samples, 95),
            p99: Metrics.percentile(samples, 99),
            max: samples.max || 0.0,
            mean: samples.empty? ? 0.0 : samples.sum / samples.length
          }
        }
      end

      def build_summary(results)
        {
          config: {
            requests: @config.requests,
            warmup: @config.warmup,
            body_bytes: @config.body_bytes,
            stream_bytes: @config.stream_bytes,
            scenarios: @config.scenarios
          },
          environment: {
            ruby_version: RUBY_VERSION,
            node_version: @server.ready.fetch("nodeVersion"),
            platform: @server.ready.fetch("platform")
          },
          results:,
          deltas: deltas(results),
          output_dir:
        }
      end

      def deltas(results)
        baseline_name = results.key?("fastify_tcp") ? "fastify_tcp" : "native_tcp"
        baseline = results[baseline_name]
        return {} unless baseline

        results.each_with_object({}) do |(scenario, scenario_results), memo|
          next if scenario == baseline_name

          memo[scenario] = PROBE_CASES.keys.each_with_object({}) do |case_name, case_memo|
            baseline_p95 = baseline.dig(case_name, :latency_ms, :p95)
            scenario_p95 = scenario_results.dig(case_name, :latency_ms, :p95)
            next unless baseline_p95 && scenario_p95

            case_memo[case_name] = { p95_ms_vs_baseline: scenario_p95 - baseline_p95 }
          end
        end
      end

      def write_summary(summary)
        FileUtils.mkdir_p(output_dir)
        File.write(File.join(output_dir, "transport_probe_summary.json"), JSON.pretty_generate(summary))
      end

      def output_dir
        @output_dir ||= @config.output_dir || File.join(
          Dir.pwd,
          "tmp",
          "load-tests",
          "transport-probe",
          Time.now.utc.strftime("%Y-%m-%dT%H-%M-%SZ")
        )
      end

      def print_summary(summary)
        puts "Renderer transport probe summary"
        puts "Output: #{summary[:output_dir]}"
        PROBE_CASES.each_key do |case_name|
          puts "\n#{case_name}"
          puts "scenario\trequests\tfailures\trps\tp50(ms)\tp95(ms)\tp99(ms)"
          summary[:results].each do |scenario, scenario_results|
            row = scenario_results.fetch(case_name)
            lat = row.fetch(:latency_ms)
            puts [
              scenario,
              row.fetch(:requests),
              row.fetch(:failures),
              format("%.2f", row.fetch(:rps)),
              format_optional(lat.fetch(:p50)),
              format_optional(lat.fetch(:p95)),
              format_optional(lat.fetch(:p99))
            ].join("\t")
          end
        end
      end

      def format_optional(value)
        value.nil? ? "n/a" : format("%.3f", value)
      end
    end

    class NodeServer
      attr_reader :ready, :endpoints

      def self.start(config)
        new(config).tap(&:start)
      end

      def initialize(config)
        @config = config
        @stderr_lines = []
      end

      def start
        @stdin, @stdout, @stderr, @wait_thread = Open3.popen3(*command)
        @stderr_reader = Thread.new { read_stderr }
        @ready = read_ready
        @endpoints = @ready.fetch("endpoints")
      rescue StandardError
        stop
        raise
      end

      def stop
        close_stdin
        terminate_process
      rescue Errno::ESRCH
        nil
      ensure
        close_pipes
      end

      private

      def close_stdin
        @stdin&.close unless @stdin&.closed?
      end

      def terminate_process
        return unless @wait_thread

        Process.kill("TERM", @wait_thread.pid) if @wait_thread.alive?
        @wait_thread.join(5)
        Process.kill("KILL", @wait_thread.pid) if @wait_thread.alive?
      rescue Errno::ESRCH
        nil
      end

      def close_pipes
        @stderr_reader&.join(1)
        [@stdout, @stderr].each { |io| io&.close unless io&.closed? }
      end

      def command
        [
          @config.node_bin,
          @config.server_script,
          "--scenarios",
          @config.scenarios.join(","),
          "--socket-path",
          @config.socket_path,
          "--body-bytes",
          @config.body_bytes.to_s,
          "--stream-bytes",
          @config.stream_bytes.to_s
        ]
      end

      def read_ready
        line = Timeout.timeout(@config.startup_timeout) { @stdout.gets }
        unless line
          @stderr_reader&.join(0.2)
          raise UserError, "transport probe server did not print readiness JSON: #{stderr_preview}"
        end

        JSON.parse(line)
      rescue Timeout::Error
        raise UserError, "transport probe server did not start within #{@config.startup_timeout}s: #{stderr_preview}"
      rescue JSON::ParserError => e
        raise UserError, "transport probe server printed invalid readiness JSON: #{e.message}"
      end

      def read_stderr
        @stderr.each_line do |line|
          @stderr_lines << line
          @stderr_lines.shift while @stderr_lines.length > 40
        end
      rescue IOError
        nil
      end

      def stderr_preview
        @stderr_lines.join.strip
      end
    end
  end
end

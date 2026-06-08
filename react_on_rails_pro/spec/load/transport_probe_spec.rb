# frozen_string_literal: true

require_relative "spec_helper"
require "transport_probe"

RSpec.describe RendererHarness::TransportProbe do
  describe RendererHarness::TransportProbe::Config do
    it "parses default benchmark parameters" do
      config = described_class.parse([])

      expect(config).to have_attributes(
        requests: 3000,
        warmup: 300,
        body_bytes: 4096,
        stream_bytes: 16_384,
        scenarios: %w[fastify_tcp native_tcp native_uds],
        node_bin: "node",
        startup_timeout: 10.0
      )
    end

    it "parses scenario selection and UDS skipping" do
      config = described_class.parse(["--scenarios", "fastify_tcp,native_tcp,native_uds", "--skip-uds"])

      expect(config.scenarios).to eq(%w[fastify_tcp native_tcp])
    end

    it "rejects unknown scenarios" do
      expect do
        described_class.parse(["--scenarios", "fastify_tcp,missing"])
      end.to raise_error(ArgumentError, /unknown scenario\(s\): missing/)
    end

    it "rejects non-positive request counts" do
      expect do
        described_class.parse(["--requests", "0"])
      end.to raise_error(ArgumentError, /--requests must be >= 1/)
    end
  end

  describe RendererHarness::TransportProbe::Runner do
    def config(**overrides)
      RendererHarness::TransportProbe::Config.new(
        {
          requests: 2,
          warmup: 0,
          body_bytes: 10,
          stream_bytes: 20,
          scenarios: %w[fastify_tcp native_tcp],
          node_bin: "node",
          server_script: "server.mjs",
          socket_path: "/tmp/probe.sock",
          startup_timeout: 1.0,
          output_dir: nil
        }.merge(overrides)
      )
    end

    it "builds explicit scheme and authority options for UDS clients" do
      runner = described_class.new(config)
      endpoint = {
        "name" => "native_uds",
        "kind" => "uds",
        "socketPath" => "/tmp/probe.sock",
        "scheme" => "http",
        "authority" => "localhost"
      }

      _endpoint_obj, options = runner.send(:client_options, endpoint)

      expect(options).to include(
        protocol: Async::HTTP::Protocol::HTTP2,
        scheme: "http",
        authority: "localhost",
        retries: 0
      )
    end

    it "summarizes latency samples with failures and throughput" do
      runner = described_class.new(config)

      summary = runner.send(:summarize, [1.0, 2.0, 3.0], failures: 1, elapsed: 0.5)

      expect(summary).to include(requests: 4, failures: 1, rps: 6.0)
      expect(summary.fetch(:latency_ms)).to include(p50: 2.0, max: 3.0)
    end

    it "computes p95 deltas against the Fastify TCP baseline" do
      runner = described_class.new(config)
      results = {
        "fastify_tcp" => {
          "small_unary" => { latency_ms: { p95: 2.0 } },
          "stream_16kb" => { latency_ms: { p95: 4.0 } }
        },
        "native_tcp" => {
          "small_unary" => { latency_ms: { p95: 1.5 } },
          "stream_16kb" => { latency_ms: { p95: 3.0 } }
        }
      }

      deltas = runner.send(:deltas, results)

      expect(deltas).to eq(
        "native_tcp" => {
          "small_unary" => { p95_ms_vs_baseline: -0.5 },
          "stream_16kb" => { p95_ms_vs_baseline: -1.0 }
        }
      )
    end
  end

  describe RendererHarness::TransportProbe::NodeServer do
    def config(**overrides)
      RendererHarness::TransportProbe::Config.new(
        {
          requests: 2,
          warmup: 0,
          body_bytes: 2_000_000,
          stream_bytes: 20,
          scenarios: %w[fastify_tcp native_tcp],
          node_bin: "node",
          server_script: "server.mjs",
          socket_path: "/tmp/probe.sock",
          startup_timeout: 1.0,
          output_dir: nil
        }.merge(overrides)
      )
    end

    it "passes body bytes to the Node probe server" do
      server = described_class.new(config(body_bytes: 2_500_000))

      expect(server.send(:command)).to include("--body-bytes", "2500000")
    end

    it "does not mask node spawn failures while cleaning up pipes" do
      expect do
        described_class.start(config(node_bin: "/path/to/missing-node"))
      end.to raise_error(Errno::ENOENT)
    end
  end

  describe "transport_probe_server.mjs" do
    it "does not remove the custom socket path when native_uds is not running" do
      Dir.mktmpdir do |dir|
        socket_path = File.join(dir, "custom.sock")
        File.write(socket_path, "keep me")
        server_script = RendererHarness::TransportProbe::Config.send(:default_server_script)
        stdin, stdout, stderr, wait_thread = Open3.popen3(
          "node",
          server_script,
          "--scenarios",
          "native_tcp",
          "--socket-path",
          socket_path
        )

        ready = Timeout.timeout(5) { JSON.parse(stdout.gets) }
        expect(ready.fetch("endpoints").map { |endpoint| endpoint.fetch("name") }).to eq(["native_tcp"])

        Process.kill("TERM", wait_thread.pid)
        wait_thread.join(5)

        expect(File.read(socket_path)).to eq("keep me")
      ensure
        stdin&.close unless stdin&.closed?
        stdout&.close unless stdout&.closed?
        stderr&.close unless stderr&.closed?
        Process.kill("KILL", wait_thread.pid) if wait_thread&.alive?
      end
    end

    it "fails without removing a regular file used as the native_uds socket path" do
      Dir.mktmpdir do |dir|
        socket_path = File.join(dir, "custom.sock")
        File.write(socket_path, "keep me")
        server_script = RendererHarness::TransportProbe::Config.send(:default_server_script)
        stdin, stdout, stderr, wait_thread = Open3.popen3(
          "node",
          server_script,
          "--scenarios",
          "native_uds",
          "--socket-path",
          socket_path
        )
        stdin.close

        status = Timeout.timeout(5) { wait_thread.value }

        expect(status).not_to be_success
        expect(stderr.read).to include("socket path exists and is not a socket")
        expect(File.read(socket_path)).to eq("keep me")
      ensure
        stdin&.close unless stdin&.closed?
        stdout&.close unless stdout&.closed?
        stderr&.close unless stderr&.closed?
        Process.kill("KILL", wait_thread.pid) if wait_thread&.alive?
      end
    end
  end
end

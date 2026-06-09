# frozen_string_literal: true

require_relative "spec_helper"
require "stringio"
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

    it "applies UDS skipping after all scenario options are parsed" do
      config = described_class.parse(["--skip-uds", "--scenarios", "fastify_tcp,native_tcp,native_uds"])

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

    it "rejects non-float startup timeout values" do
      expect do
        described_class.send(:validate_positive_float!, "--startup-timeout", "10abc")
      end.to raise_error(ArgumentError, /--startup-timeout must be > 0/)
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

    it "computes latency deltas against the Fastify TCP baseline" do
      runner = described_class.new(config)
      results = {
        "fastify_tcp" => {
          "small_unary" => { latency_ms: { p50: 1.0, p95: 2.0, p99: 3.0 } },
          "stream_16kb" => { latency_ms: { p50: 2.0, p95: 4.0, p99: 6.0 } }
        },
        "native_tcp" => {
          "small_unary" => { latency_ms: { p50: 0.75, p95: 1.5, p99: 2.25 } },
          "stream_16kb" => { latency_ms: { p50: 1.5, p95: 3.0, p99: 4.5 } }
        }
      }

      deltas = runner.send(:deltas, results)

      expect(deltas).to eq(
        "native_tcp" => {
          "small_unary" => { p50_ms_vs_baseline: -0.25, p95_ms_vs_baseline: -0.5, p99_ms_vs_baseline: -0.75 },
          "stream_16kb" => { p50_ms_vs_baseline: -0.5, p95_ms_vs_baseline: -1.0, p99_ms_vs_baseline: -1.5 }
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

    it "rejects readiness JSON that is not an object with endpoints" do
      server = described_class.new(config)
      server.instance_variable_set(:@stdout, StringIO.new("#{JSON.generate('warning line')}\n"))

      expect do
        server.send(:read_ready)
      end.to raise_error(
        RendererHarness::TransportProbe::UserError,
        /readiness JSON must be an object with an endpoints array/
      )
    end
  end

  describe "transport_probe_server.mjs" do
    def close_probe_io(stdin, stdout, stderr)
      [stdin, stdout, stderr].each { |io| io&.close unless io&.closed? }
    end

    def terminate_probe_process(wait_thread, signal)
      return unless wait_thread&.alive?

      Process.kill(signal, wait_thread.pid)
      wait_thread.join(5) if signal == "TERM"
      Process.kill("KILL", wait_thread.pid) if wait_thread.alive?
    rescue Errno::ESRCH
      nil
    end

    def close_probe_server(stdin, stdout, stderr, wait_thread, signal: "KILL")
      close_probe_io(stdin, stdout, stderr)
      terminate_probe_process(wait_thread, signal)
    end

    def post_native_probe(origin, body)
      endpoint = Async::HTTP::Endpoint.parse(origin, protocol: Async::HTTP::Protocol::HTTP2)
      response = nil
      Sync do
        Async::HTTP::Client.open(endpoint, protocol: Async::HTTP::Protocol::HTTP2, retries: 0) do |client|
          response = client.post(
            "/probe/unary",
            headers: Protocol::HTTP::Headers[[["content-type", "application/octet-stream"]]],
            body:
          )
          response_body = +""
          response.body&.each { |chunk| response_body << chunk }
          [response.status, JSON.parse(response_body)]
        ensure
          response&.body&.close
        end
      end
    end

    it "does not remove the custom socket path when native_uds is not running" do
      Dir.mktmpdir do |dir|
        socket_path = File.join(dir, "custom.sock")
        File.write(socket_path, "keep me")
        server_script = RendererHarness::TransportProbe::Config.send(:default_server_script)
        stdin = stdout = stderr = wait_thread = nil
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
        close_probe_server(stdin, stdout, stderr, wait_thread)
      end
    end

    it "applies the body byte limit to native_tcp request bodies" do
      Dir.mktmpdir do |dir|
        server_script = RendererHarness::TransportProbe::Config.send(:default_server_script)
        stdin = stdout = stderr = wait_thread = nil
        stdin, stdout, stderr, wait_thread = Open3.popen3(
          "node",
          server_script,
          "--scenarios",
          "native_tcp",
          "--socket-path",
          File.join(dir, "unused.sock"),
          "--body-bytes",
          "4"
        )

        ready = Timeout.timeout(5) { JSON.parse(stdout.gets) }
        native_endpoint = ready.fetch("endpoints").find { |endpoint| endpoint.fetch("name") == "native_tcp" }

        status, payload = post_native_probe(native_endpoint.fetch("origin"), "12345")

        expect(status).to eq(413)
        expect(payload).to include(
          "ok" => false,
          "error" => include("request body exceeded --body-bytes limit (4)")
        )
      ensure
        close_probe_server(stdin, stdout, stderr, wait_thread, signal: "TERM")
      end
    end

    it "rejects non-decimal body byte values" do
      Dir.mktmpdir do |dir|
        server_script = RendererHarness::TransportProbe::Config.send(:default_server_script)

        _stdout, stderr, status = Open3.capture3(
          "node",
          server_script,
          "--scenarios",
          "native_tcp",
          "--socket-path",
          File.join(dir, "unused.sock"),
          "--body-bytes",
          "1e6"
        )

        expect(status).not_to be_success
        expect(stderr).to include("--body-bytes must be a positive integer")
      end
    end

    it "keeps native_tcp alive when an oversized request is aborted" do
      Dir.mktmpdir do |dir|
        server_script = RendererHarness::TransportProbe::Config.send(:default_server_script)
        stdin = stdout = stderr = wait_thread = nil
        stdin, stdout, stderr, wait_thread = Open3.popen3(
          "node",
          server_script,
          "--scenarios",
          "native_tcp",
          "--socket-path",
          File.join(dir, "unused.sock"),
          "--body-bytes",
          "4"
        )

        ready = Timeout.timeout(5) { JSON.parse(stdout.gets) }
        native_endpoint = ready.fetch("endpoints").find { |endpoint| endpoint.fetch("name") == "native_tcp" }
        abort_script = <<~JS
          const http2 = require("node:http2");
          const client = http2.connect(process.argv[1]);
          const request = client.request({
            ":method": "POST",
            ":path": "/probe/unary",
            "content-type": "application/octet-stream",
          });
          request.on("error", () => {});
          request.write(Buffer.alloc(5, "x"));
          request.close(http2.constants.NGHTTP2_CANCEL);
          setTimeout(() => client.close(), 50);
          setTimeout(() => process.exit(0), 100);
        JS

        _stdout, client_stderr, client_status = Open3.capture3(
          "node",
          "-e",
          abort_script,
          native_endpoint.fetch("origin")
        )
        expect(client_status).to be_success, client_stderr

        status, payload = post_native_probe(native_endpoint.fetch("origin"), "1234")
        expect(status).to eq(200)
        expect(payload).to include("ok" => true, "receivedBytes" => 4)
      ensure
        close_probe_server(stdin, stdout, stderr, wait_thread, signal: "TERM")
      end
    end

    it "fails without removing a regular file used as the native_uds socket path" do
      Dir.mktmpdir do |dir|
        socket_path = File.join(dir, "custom.sock")
        File.write(socket_path, "keep me")
        server_script = RendererHarness::TransportProbe::Config.send(:default_server_script)
        stdin = stdout = stderr = wait_thread = nil
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
        expect(stderr.read).to include("socket path already exists")
        expect(File.read(socket_path)).to eq("keep me")
      ensure
        close_probe_server(stdin, stdout, stderr, wait_thread)
      end
    end
  end
end

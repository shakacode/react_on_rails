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

    it "describes the body byte option as payload size and server limit" do
      expect do
        described_class.parse(["--help"])
      end.to output(/Request payload size and server body limit/).to_stdout.and raise_error(SystemExit)
    end

    it "rejects non-positive startup timeout values" do
      expect do
        described_class.parse(["--startup-timeout", "0"])
      end.to raise_error(ArgumentError, /--startup-timeout must be > 0/)
    end

    {
      "--scenarios" => "--skip-uds",
      "--node-bin" => "--requests",
      "--server-script" => "--requests",
      "--socket-path" => "--requests",
      "--output-dir" => "--skip-uds"
    }.each do |flag, next_token|
      it "rejects #{flag} without a value before another flag" do
        expect do
          described_class.parse([flag, next_token])
        end.to raise_error(ArgumentError, /#{Regexp.escape(flag)} requires a value/)
      end
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

    it "includes bounded response details in non-200 request errors" do
      runner = described_class.new(config)
      response = instance_double(
        Async::HTTP::Protocol::Response,
        status: 413,
        body: StringIO.new('{"ok":false,"error":"request body exceeded --body-bytes limit (10)"}')
      )
      client = instance_double(Async::HTTP::Client)

      allow(client).to receive(:post).and_return(response)

      expect do
        runner.send(:perform_request, client, "/probe/unary", "too large")
      end.to raise_error(RuntimeError, /HTTP 413: .*request body exceeded --body-bytes limit/)
    end

    it "caps non-200 response details" do
      runner = described_class.new(config)
      response = instance_double(
        Async::HTTP::Protocol::Response,
        status: 500,
        body: StringIO.new("#{'x' * 5000}tail")
      )
      client = instance_double(Async::HTTP::Client)

      allow(client).to receive(:post).and_return(response)

      expect do
        runner.send(:perform_request, client, "/probe/unary", "body")
      end.to raise_error(RuntimeError) { |error| expect(error.message).not_to include("tail") }
    end

    it "computes latency deltas against the Fastify TCP baseline" do
      runner = described_class.new(config)
      results = {
        "fastify_tcp" => {
          "small_unary" => { latency_ms: { p50: 1.0, p95: 2.0, p99: 3.0 } },
          "stream_response" => { latency_ms: { p50: 2.0, p95: 4.0, p99: 6.0 } }
        },
        "native_tcp" => {
          "small_unary" => { latency_ms: { p50: 0.75, p95: 1.5, p99: 2.25 } },
          "stream_response" => { latency_ms: { p50: 1.5, p95: 3.0, p99: 4.5 } }
        }
      }

      deltas = runner.send(:deltas, results)

      expect(runner.send(:baseline_name, results)).to eq("fastify_tcp")
      expect(deltas).to eq(
        "native_tcp" => {
          "small_unary" => { p50_ms_vs_baseline: -0.25, p95_ms_vs_baseline: -0.5, p99_ms_vs_baseline: -0.75 },
          "stream_response" => { p50_ms_vs_baseline: -0.5, p95_ms_vs_baseline: -1.0, p99_ms_vs_baseline: -1.5 }
        }
      )
    end

    it "records native_tcp as the fallback baseline when Fastify is omitted" do
      runner = described_class.new(config)
      server = instance_double(
        RendererHarness::TransportProbe::NodeServer,
        ready: { "nodeVersion" => "v22.0.0", "platform" => "darwin arm64" }
      )
      results = {
        "native_tcp" => {
          "small_unary" => { latency_ms: { p50: 1.0, p95: 2.0, p99: 3.0 } }
        },
        "native_uds" => {
          "small_unary" => { latency_ms: { p50: 0.75, p95: 1.5, p99: 2.25 } }
        }
      }
      runner.instance_variable_set(:@server, server)

      summary = runner.send(:build_summary, results)

      expect(summary[:baseline]).to eq("native_tcp")
      expect(summary[:deltas]).to eq(
        "native_uds" => {
          "small_unary" => {
            p50_ms_vs_baseline: -0.25,
            p95_ms_vs_baseline: -0.5,
            p99_ms_vs_baseline: -0.75
          }
        }
      )
    end

    it "keeps machine-local output paths out of the JSON summary" do
      runner = described_class.new(config)
      server = instance_double(
        RendererHarness::TransportProbe::NodeServer,
        ready: { "nodeVersion" => "v22.0.0", "platform" => "darwin arm64" }
      )
      runner.instance_variable_set(:@server, server)

      summary = runner.send(:build_summary, {})

      expect(summary).not_to have_key(:output_dir)
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

    it "rejects readiness endpoints without string names" do
      server = described_class.new(config)
      ready = {
        endpoints: [
          { kind: "tcp", origin: "http://127.0.0.1:3000" }
        ]
      }
      server.instance_variable_set(:@stdout, StringIO.new("#{JSON.generate(ready)}\n"))

      expect do
        server.send(:read_ready)
      end.to raise_error(
        RendererHarness::TransportProbe::UserError,
        /endpoints\[0\]\.name must be a non-empty string/
      )
    end

    it "rejects tcp readiness endpoints without origins" do
      server = described_class.new(config)
      ready = {
        endpoints: [
          { name: "native_tcp", kind: "tcp" }
        ]
      }
      server.instance_variable_set(:@stdout, StringIO.new("#{JSON.generate(ready)}\n"))

      expect do
        server.send(:read_ready)
      end.to raise_error(
        RendererHarness::TransportProbe::UserError,
        /endpoints\[0\]\.origin must be a non-empty string/
      )
    end

    it "rejects uds readiness endpoints without socket fields" do
      server = described_class.new(config)
      ready = {
        endpoints: [
          { name: "native_uds", kind: "uds", socketPath: "/tmp/probe.sock", scheme: "http" }
        ]
      }
      server.instance_variable_set(:@stdout, StringIO.new("#{JSON.generate(ready)}\n"))

      expect do
        server.send(:read_ready)
      end.to raise_error(
        RendererHarness::TransportProbe::UserError,
        /endpoints\[0\]\.authority must be a non-empty string/
      )
    end

    it "ignores already-closed stdin errors while stopping" do
      server = described_class.new(config)
      stdin = instance_double(IO)
      allow(stdin).to receive(:close).and_raise(IOError, "closed stream")
      server.instance_variable_set(:@stdin, stdin)

      expect { server.stop }.not_to raise_error
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
        Async::Task.current.with_timeout(5) do
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
          // Bounded grace period for this dev-tool regression test: let the
          // server observe the cancelled stream before closing the session.
          setTimeout(() => client.close(), 200);
          setTimeout(() => process.exit(0), 400);
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

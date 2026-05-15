# frozen_string_literal: true

require_relative "spec_helper"
require "fakefs/safe"

describe ReactOnRailsPro::Request do
  let(:logger_mock) { instance_double(ActiveSupport::Logger).as_null_object }
  let(:renderer_url) { "http://node-renderer.com:3800" }
  let(:render_path) { "/render" }
  let(:render_full_url) { "#{renderer_url}#{render_path}" }
  let(:server_bundle_path) { "public/webpack/production/server_bundle.js" }
  let(:rsc_server_bundle_path) { "public/webpack/production/rsc_server_bundle.js" }
  let(:renderer_bundle_file_name) { "1234567890.js" }
  let(:rsc_renderer_bundle_file_name) { "9876543210.js" }

  before do
    FakeFS.activate!
    FileUtils.mkdir_p(File.dirname(server_bundle_path))
    File.write(server_bundle_path, 'console.log("mock bundle");')
    FileUtils.mkdir_p(File.dirname(rsc_server_bundle_path))
    File.write(rsc_server_bundle_path, 'console.log("mock RSC bundle");')

    clear_stream_mocks
    allow(ReactOnRailsPro.configuration).to receive_messages(renderer_url: renderer_url, renderer_http_pool_size: 20)
    install_renderer_http_client_mock(renderer_url)
    allow(Rails).to receive(:logger).and_return(logger_mock)

    allow(ReactOnRailsPro::ServerRenderingPool::NodeRenderingPool).to receive_messages(
      renderer_bundle_file_name: renderer_bundle_file_name, rsc_renderer_bundle_file_name: rsc_renderer_bundle_file_name
    )
    allow(ReactOnRails::Utils).to receive(:server_bundle_js_file_path).and_return(server_bundle_path)

    allow(ReactOnRailsPro::Utils).to receive(:rsc_bundle_js_file_path).and_return(rsc_server_bundle_path)
  end

  after do
    FakeFS.deactivate!
  end

  describe "render_code_as_stream" do
    # Build a length-prefixed wire-format frame matching what the node renderer streams.
    # Format: <metadata JSON>\t<8-char hex content byte length>\n<raw content bytes>
    def lpp(html, **metadata)
      "#{metadata.to_json}\t#{html.bytesize.to_s(16).rjust(8, '0')}\n#{html}"
    end

    it "returns a stream" do
      stream = described_class.render_code_as_stream("/render", "console.log('Hello, world!');", is_rsc_payload: false)
      expect(stream).to be_a(ReactOnRailsPro::StreamDecorator)
    end

    shared_examples "receives response in chunks" do |description, chunks_received, chunks_expected|
      it description do
        mock_streaming_response(render_full_url, 200) do |yielder|
          chunks_received.each do |chunk|
            yielder.call(chunk)
          end
        end

        stream = described_class.render_code_as_stream("/render", "console.log('Hello, world!');",
                                                       is_rsc_payload: false)
        chunks = []
        stream.each_chunk do |chunk|
          chunks << chunk
        end
        expect(chunks).to eq(chunks_expected)
      end
    end

    it_behaves_like "receives response in chunks",
                    "yields parsed length-prefixed frames in order",
                    [
                      "{\"consoleReplayScript\":\"\"}\t0000000b\nFirst chunk",
                      "{\"consoleReplayScript\":\"\"}\t0000000c\nSecond chunk",
                      "{\"consoleReplayScript\":\"\"}\t0000000b\nFinal chunk"
                    ],
                    [
                      { "html" => "First chunk", "consoleReplayScript" => "" },
                      { "html" => "Second chunk", "consoleReplayScript" => "" },
                      { "html" => "Final chunk", "consoleReplayScript" => "" }
                    ]

    packed = "{\"consoleReplayScript\":\"\"}\t0000000b\nFirst chunk" \
             "{\"consoleReplayScript\":\"\"}\t0000000c\nSecond chunk"
    it_behaves_like "receives response in chunks",
                    "parses multiple frames packed into a single chunk",
                    [packed, "{\"consoleReplayScript\":\"\"}\t0000000b\nFinal chunk"],
                    [
                      { "html" => "First chunk", "consoleReplayScript" => "" },
                      { "html" => "Second chunk", "consoleReplayScript" => "" },
                      { "html" => "Final chunk", "consoleReplayScript" => "" }
                    ]

    it_behaves_like "receives response in chunks",
                    "reassembles frames split across HTTP chunk boundaries",
                    [
                      "{\"consoleReplayScript\":\"\"}\t0000000b\nFirst ",
                      "chunk{\"consoleReplayScript\":\"\"}\t0000000b\nFinal chunk"
                    ],
                    [
                      { "html" => "First chunk", "consoleReplayScript" => "" },
                      { "html" => "Final chunk", "consoleReplayScript" => "" }
                    ]

    it "does not warn based on lazy streaming response creation time" do
      allow(ReactOnRailsPro.configuration).to receive(:renderer_http_pool_warn_timeout).and_return(0.5)
      allow(Time).to receive(:now).and_return(Time.at(0), Time.at(1))
      mock_streaming_response(render_full_url, 200) do |yielder|
        yielder.call(lpp("rendered"))
      end

      stream = described_class.render_code_as_stream("/render", "console.log('Hello, world!');",
                                                     is_rsc_payload: false)
      chunks = []
      stream.each_chunk do |chunk|
        chunks << chunk
      end

      expect(chunks).to eq([{ "html" => "rendered" }])
      expect(logger_mock).not_to have_received(:warn)
    end

    it "warns when a streaming response exceeds the first chunk warning timeout" do
      allow(ReactOnRailsPro.configuration).to receive(:renderer_http_pool_warn_timeout).and_return(0.5)
      allow(Time).to receive(:now).and_return(Time.at(0), Time.at(0), Time.at(0.75))
      mock_streaming_response(render_full_url, 200) do |yielder|
        yielder.call(lpp("rendered"))
      end

      stream = described_class.render_code_as_stream("/render", "console.log('Hello, world!');",
                                                     is_rsc_payload: false)
      chunks = []
      stream.each_chunk do |chunk|
        chunks << chunk
      end

      expect(chunks).to eq([{ "html" => "rendered" }])
      expect(logger_mock).to have_received(:warn).with(
        "Streaming request to /render delivered first chunk after 0.75 seconds, expected at most 0.5."
      )
    end

    it "does not warn based on lazy streaming response creation time" do
      allow(ReactOnRailsPro.configuration).to receive(:renderer_http_pool_warn_timeout).and_return(0.5)
      allow(Time).to receive(:now).and_return(Time.at(0), Time.at(1))
      mock_streaming_response(render_full_url, 200) do |yielder|
        yielder.call("rendered\n")
      end

      stream = described_class.render_code_as_stream("/render", "console.log('Hello, world!');",
                                                     is_rsc_payload: false)
      chunks = []
      stream.each_chunk do |chunk|
        chunks << chunk
      end

      expect(chunks).to eq(["rendered"])
      expect(logger_mock).not_to have_received(:warn)
    end

    it "warns when a streaming response exceeds the first chunk warning timeout" do
      allow(ReactOnRailsPro.configuration).to receive(:renderer_http_pool_warn_timeout).and_return(0.5)
      allow(Time).to receive(:now).and_return(Time.at(0), Time.at(0), Time.at(0.75))
      mock_streaming_response(render_full_url, 200) do |yielder|
        yielder.call("rendered\n")
      end

      stream = described_class.render_code_as_stream("/render", "console.log('Hello, world!');",
                                                     is_rsc_payload: false)
      chunks = []
      stream.each_chunk do |chunk|
        chunks << chunk
      end

      expect(chunks).to eq(["rendered"])
      expect(logger_mock).to have_received(:warn).with(
        "Streaming request to /render delivered first chunk after 0.75 seconds, expected at most 0.5."
      )
    end

    [true, false].each do |use_delay|
      it "processes each chunk immediately when use_delay is #{use_delay}" do
        mocked_block = mock_block

        mock_streaming_response(render_full_url, 200) do |yielder|
          sleep(0.2) if use_delay
          yielder.call(lpp("First chunk"))
          expect(mocked_block).to have_received(:call).with(hash_including("html" => "First chunk"))

          sleep(0.2) if use_delay
          yielder.call(lpp("Second chunk"))
          expect(mocked_block).to have_received(:call).with(hash_including("html" => "Second chunk"))

          sleep(0.2) if use_delay
          yielder.call(lpp("Final chunk"))
          expect(mocked_block).to have_received(:call).with(hash_including("html" => "Final chunk"))
        end

        stream = described_class.render_code_as_stream("/render", "console.log('Hello, world!');",
                                                       is_rsc_payload: false)
        stream.each_chunk(&mocked_block.block)
      end
    end

    it "reuploads bundles when bundle not found on renderer" do
      first_request_info = mock_streaming_response(render_full_url, ReactOnRailsPro::STATUS_SEND_BUNDLE,
                                                   count: 1) do |yielder|
        yielder.call("Bundle not found\n")
      end
      second_request_info = mock_streaming_response(render_full_url, 200) do |yielder|
        yielder.call(lpp("Hello, world!"))
      end

      stream = described_class.render_code_as_stream("/render", "console.log('Hello, world!');", is_rsc_payload: false)
      chunks = []
      stream.each_chunk do |chunk|
        chunks << chunk
      end
      expect(chunks).to eq([{ "html" => "Hello, world!" }])

      # First request should not have a bundle
      expect(first_request_info[:request].body.to_s).to include("renderingRequest=console.log")
      expect(first_request_info[:request].body.to_s).not_to include("bundle")

      # Second request should have a bundle
      second_request_form = second_request_info[:request].form

      expect(second_request_form).to have_key("bundle_server_bundle.js")
      expect(second_request_form["bundle_server_bundle.js"][:body]).to be_a(FakeFS::Pathname)
      expect(second_request_form["bundle_server_bundle.js"][:body].to_s).to eq(server_bundle_path)
    end

    it "raises duplicate bundle upload error when server asks for bundle twice" do
      first_request_info = mock_streaming_response(render_full_url, ReactOnRailsPro::STATUS_SEND_BUNDLE) do |yielder|
        yielder.call("Bundle not found\n")
      end
      second_request_info = mock_streaming_response(render_full_url, ReactOnRailsPro::STATUS_SEND_BUNDLE) do |yielder|
        yielder.call("Bundle still not found\n")
      end

      stream = described_class.render_code_as_stream("/render", "console.log('Hello, world!');", is_rsc_payload: false)
      expect do
        stream.each_chunk do |chunk|
          # Do nothing
        end
      end.to raise_error(ReactOnRailsPro::Error, /The bundle has already been uploaded/)

      # First request should not have a bundle
      expect(first_request_info[:request].body.to_s).to include("renderingRequest=console.log")
      expect(first_request_info[:request].body.to_s).not_to include("bundle")

      # Second request should have a bundle
      second_request_form = second_request_info[:request].form

      expect(second_request_form).to have_key("bundle_server_bundle.js")
      expect(second_request_form["bundle_server_bundle.js"][:body]).to be_a(FakeFS::Pathname)
      expect(second_request_form["bundle_server_bundle.js"][:body].to_s).to eq(server_bundle_path)
    end

    it "raises incompatible error when server returns incompatible error" do
      mocked_block = mock_block
      error_body = "Renderer version 1.2.3 is incompatible with this react_on_rails_pro version."

      mock_streaming_response(render_full_url, ReactOnRailsPro::STATUS_INCOMPATIBLE) do |yielder|
        yielder.call(error_body)
      end

      stream = described_class.render_code_as_stream("/render", "console.log('Hello, world!');", is_rsc_payload: false)
      expect do
        stream.each_chunk(&mocked_block.block)
      end.to raise_error(ReactOnRailsPro::Error, error_body)

      expect(mocked_block).not_to have_received(:call)
    end

    it "raises a renderer bad request error when server returns status code 400" do
      mocked_block = mock_block

      mock_streaming_response(render_full_url, ReactOnRailsPro::STATUS_BAD_REQUEST) do |yielder|
        yielder.call("Invalid \"renderingRequest\" field in render request.")
      end

      stream = described_class.render_code_as_stream("/render", "console.log('Hello, world!');",
                                                     is_rsc_payload: false)
      expect do
        stream.each_chunk(&mocked_block.block)
      end.to raise_error(
        ReactOnRailsPro::Error,
        /Renderer rejected malformed request or hit an unhandled VM error: 400:\n/
      )

      expect(mocked_block).not_to have_received(:call)
    end

    (420..499).step(20).each do |status_code|
      it "raises an error when server returns error with status code #{status_code}" do
        mocked_block = mock_block

        mock_streaming_response(render_full_url, status_code) do |yielder|
          yielder.call("Unknown error message")
        end

        stream = described_class.render_code_as_stream("/render", "console.log('Hello, world!');",
                                                       is_rsc_payload: false)
        expect do
          stream.each_chunk(&mocked_block.block)
        end.to raise_error(ReactOnRailsPro::Error, /#{status_code}:\nUnknown error message/)

        expect(mocked_block).not_to have_received(:call)
      end
    end

    it "raises a renderer error when streaming response consumption hits a connection error" do
      mocked_block = mock_block

      mock_streaming_response(render_full_url, 200) do |_yielder|
        raise ReactOnRailsPro::RendererHttpClient::ConnectionError, "renderer reset connection"
      end

      stream = described_class.render_code_as_stream("/render", "console.log('Hello, world!');",
                                                     is_rsc_payload: false)
      expect do
        stream.each_chunk(&mocked_block.block)
      end.to raise_error(ReactOnRailsPro::Error, /renderer reset connection/)

      expect(mocked_block).not_to have_received(:call)
    end
  end

  describe "render_code" do
    it "warns when a non-streaming request exceeds the warning timeout" do
      allow(ReactOnRailsPro.configuration).to receive(:renderer_http_pool_warn_timeout).and_return(0.5)
      allow(Time).to receive(:now).and_return(Time.at(0), Time.at(1))
      mock_streaming_response(render_full_url, 200) do |yielder|
        yielder.call("rendered")
      end

      response = described_class.render_code(render_path, "console.log('Hello, world!');", false)

      expect(response.body).to eq("rendered")
      expect(logger_mock).to have_received(:warn).with(
        "Request to /render took 1.0 seconds, expected at most 0.5."
      )
    end

    it "does not warn or raise when request warning timeout is disabled" do
      allow(ReactOnRailsPro.configuration).to receive(:renderer_http_pool_warn_timeout).and_return(nil)
      mock_streaming_response(render_full_url, 200) do |yielder|
        yielder.call("rendered")
      end

      response = described_class.render_code(render_path, "console.log('Hello, world!');", false)

      expect(response.body).to eq("rendered")
      expect(logger_mock).not_to have_received(:warn)
    end
  end

  describe "render_code" do
    it "warns when a non-streaming request exceeds the warning timeout" do
      allow(ReactOnRailsPro.configuration).to receive(:renderer_http_pool_warn_timeout).and_return(0.5)
      allow(Time).to receive(:now).and_return(Time.at(0), Time.at(1))
      mock_streaming_response(render_full_url, 200) do |yielder|
        yielder.call("rendered")
      end

      response = described_class.render_code(render_path, "console.log('Hello, world!');", false)

      expect(response.body).to eq("rendered")
      expect(logger_mock).to have_received(:warn).with(
        "Request to /render took 1.0 seconds, expected at most 0.5."
      )
    end

    it "does not warn or raise when request warning timeout is disabled" do
      allow(ReactOnRailsPro.configuration).to receive(:renderer_http_pool_warn_timeout).and_return(nil)
      mock_streaming_response(render_full_url, 200) do |yielder|
        yielder.call("rendered")
      end

      response = described_class.render_code(render_path, "console.log('Hello, world!');", false)

      expect(response.body).to eq("rendered")
      expect(logger_mock).not_to have_received(:warn)
    end
  end

  describe "get_form_body_for_file" do
    let(:url_path) { "http://localhost:3035/webpack/development/server-bundle.js" }

    it "returns a pathname for file paths" do
      result = described_class.send(:get_form_body_for_file, server_bundle_path)
      expect(result).to be_a(FakeFS::Pathname)
      expect(result.to_s).to eq(server_bundle_path)
    end

    it "returns response body for HTTP urls in development mode" do
      response_body = "console.log('asset');"
      response = ReactOnRailsPro::RendererHttpClient::Response.new(status: 200, body: [response_body])
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))
      allow(ReactOnRailsPro::RendererHttpClient).to receive(:get).with(
        url_path,
        connect_timeout: ReactOnRailsPro.configuration.renderer_http_pool_timeout,
        read_timeout: ReactOnRailsPro.configuration.ssr_timeout
      ).and_return(response)

      result = described_class.send(:get_form_body_for_file, url_path)
      expect(result).to eq(response_body)
    end

    it "raises ReactOnRailsPro::Error when the renderer HTTP client returns an error response" do
      http_error = ReactOnRailsPro::RendererHttpClient::ConnectionError.new("connection refused")
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))
      allow(ReactOnRailsPro::RendererHttpClient).to receive(:get).with(
        url_path,
        connect_timeout: ReactOnRailsPro.configuration.renderer_http_pool_timeout,
        read_timeout: ReactOnRailsPro.configuration.ssr_timeout
      ).and_raise(http_error)

      expect do
        described_class.send(:get_form_body_for_file, url_path)
      end.to raise_error(ReactOnRailsPro::Error, /#{Regexp.escape(url_path)}.*connection refused/) { |error|
        expect(error.cause).to be(http_error)
      }
    end

    it "raises ReactOnRailsPro::Error when the dev server returns an HTTP error status" do
      response = ReactOnRailsPro::RendererHttpClient::Response.new(status: 404, body: ["missing asset"])
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))
      allow(ReactOnRailsPro::RendererHttpClient).to receive(:get).with(
        url_path,
        connect_timeout: ReactOnRailsPro.configuration.renderer_http_pool_timeout,
        read_timeout: ReactOnRailsPro.configuration.ssr_timeout
      ).and_return(response)

      expect do
        described_class.send(:get_form_body_for_file, url_path)
      end.to raise_error(
        ReactOnRailsPro::Error,
        /Failed to fetch dev-server asset from #{Regexp.escape(url_path)}: HTTP request failed with status 404/
      ) { |error| expect(error.cause).to be_a(ReactOnRailsPro::RendererHttpClient::HTTPError) }
    end
  end

  describe "thread-safe connection management" do
    let(:mock_connection) { instance_double(ReactOnRailsPro::RendererHttpClient) }

    before do
      # Reset connection state before each test
      described_class.instance_variable_set(:@connection, nil)
    end

    after do
      # Clean up connection state after each test
      described_class.instance_variable_set(:@connection, nil)
    end

    it "creates only one connection when accessed concurrently" do
      connections_created = 0
      counter_mutex = Mutex.new

      # Stub create_connection to track calls and simulate slow creation
      allow(described_class).to receive(:create_connection) do
        counter_mutex.synchronize { connections_created += 1 }
        sleep(0.01) # Simulate connection setup time to increase race window
        mock_connection
      end

      # Simulate multiple threads racing to initialize connection
      threads = Array.new(10) do
        Thread.new { described_class.send(:connection) }
      end
      threads.each(&:join)

      # Should only create ONE connection despite concurrent calls
      expect(connections_created).to eq(1)
    end

    it "safely handles reset during concurrent access" do
      allow(described_class).to receive(:create_connection).and_return(mock_connection)
      allow(mock_connection).to receive(:close)

      errors = []
      errors_mutex = Mutex.new

      # Background threads accessing connection
      threads = Array.new(5) do
        Thread.new do
          50.times do
            described_class.send(:connection)
          rescue StandardError => e
            errors_mutex.synchronize { errors << e }
          end
        end
      end

      # Reset connection while other threads are accessing it
      sleep(0.005)
      described_class.reset_connection

      threads.each(&:join)

      expect(errors).to be_empty
    end

    it "properly closes old connection on reset" do
      old_connection = instance_double(ReactOnRailsPro::RendererHttpClient)
      new_connection = instance_double(ReactOnRailsPro::RendererHttpClient)

      # Set up initial connection
      described_class.instance_variable_set(:@connection, old_connection)

      allow(described_class).to receive(:create_connection).and_return(new_connection)
      expect(old_connection).to receive(:close)

      described_class.reset_connection

      expect(described_class.send(:connection)).to eq(new_connection)
    end
  end
end

# frozen_string_literal: true

require_relative "spec_helper"
require "fakefs/safe"
require "async"
require "async/http"
require "protocol/http"
require "protocol/http/body/readable"

describe ReactOnRailsPro::Request do
  let(:logger_mock) { instance_double(ActiveSupport::Logger).as_null_object }
  let(:renderer_url) { "http://node-renderer.com:3800" }
  let(:render_path) { "/render" }
  let(:render_full_url) { "#{renderer_url}#{render_path}" }
  let(:server_bundle_path) { "public/webpack/production/server_bundle.js" }
  let(:rsc_server_bundle_path) { "public/webpack/production/rsc_server_bundle.js" }
  let(:renderer_bundle_file_name) { "1234567890.js" }
  let(:rsc_renderer_bundle_file_name) { "9876543210.js" }

  let(:mock_client) { instance_double(Async::HTTP::Client) }
  let(:mock_endpoint) { instance_double(Async::HTTP::Endpoint) }

  before do
    FakeFS.activate!
    FileUtils.mkdir_p(File.dirname(server_bundle_path))
    File.write(server_bundle_path, 'console.log("mock bundle");')
    FileUtils.mkdir_p(File.dirname(rsc_server_bundle_path))
    File.write(rsc_server_bundle_path, 'console.log("mock RSC bundle");')

    allow(ReactOnRailsPro.configuration).to receive_messages(renderer_url: renderer_url, renderer_http_pool_size: 20)
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

  # Helper to create a mock async-http response with chunks
  def mock_response(status:, chunks: [])
    mock_body = instance_double(Protocol::HTTP::Body::Readable)
    allow(mock_body).to receive(:each) do |&block|
      chunks.each { |chunk| block.call(chunk) }
    end
    allow(mock_body).to receive(:close)

    response = instance_double(Protocol::HTTP::Response, status: status, body: mock_body)
    allow(response).to receive(:read).and_return(chunks.join)
    response
  end

  # Helper to stub the client for a sequence of responses
  def stub_client_with_responses(*responses)
    allow(described_class).to receive(:create_connection).and_return([mock_client, mock_endpoint])
    described_class.instance_variable_set(:@client, mock_client)
    described_class.instance_variable_set(:@endpoint, mock_endpoint)

    call_count = 0
    allow(mock_client).to receive(:post) do |_path, _headers, _body|
      response = responses[call_count] || responses.last
      call_count += 1
      response
    end
  end

  describe "render_code_as_stream" do
    before do
      # Reset connection state before each test
      described_class.instance_variable_set(:@client, nil)
      described_class.instance_variable_set(:@endpoint, nil)
    end

    after do
      # Clean up connection state after each test
      described_class.instance_variable_set(:@client, nil)
      described_class.instance_variable_set(:@endpoint, nil)
    end

    it "returns a stream" do
      stub_client_with_responses(mock_response(status: 200, chunks: ["chunk\n"]))

      stream = described_class.render_code_as_stream("/render", "console.log('Hello, world!');", is_rsc_payload: false)
      expect(stream).to be_a(ReactOnRailsPro::StreamDecorator)
    end

    shared_examples "receives response in chunks" do |description, chunks_received, chunks_expected|
      it description do
        stub_client_with_responses(mock_response(status: 200, chunks: chunks_received))

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
                    "yeilds chunks in order",
                    ["First chunk\n", "Second chunk\n", "Final chunk\n"],
                    ["First chunk", "Second chunk", "Final chunk"]

    it_behaves_like "receives response in chunks",
                    "separates chunks by newline",
                    ["First chunk\nSecond chunk\n", "Final chunk\n"],
                    ["First chunk", "Second chunk", "Final chunk"]

    it_behaves_like "receives response in chunks",
                    "merges chunks until newline",
                    ["First chunk", "Second chunk\n", "Final chunk\n"],
                    ["First chunkSecond chunk", "Final chunk"]

    it "processes each chunk immediately when streaming" do
      received_chunks = []

      mock_body = instance_double(Protocol::HTTP::Body::Readable)
      allow(mock_body).to receive(:each) do |&block|
        block.call("First chunk\n")
        expect(received_chunks).to include("First chunk")

        block.call("Second chunk\n")
        expect(received_chunks).to include("Second chunk")

        block.call("Final chunk\n")
      end
      allow(mock_body).to receive(:close)

      response = instance_double(Protocol::HTTP::Response, status: 200, body: mock_body)
      allow(response).to receive(:read).and_return("")

      stub_client_with_responses(response)

      stream = described_class.render_code_as_stream("/render", "console.log('Hello, world!');",
                                                     is_rsc_payload: false)
      stream.each_chunk { |chunk| received_chunks << chunk }
    end

    it "reuploads bundles when bundle not found on renderer" do
      # First request returns STATUS_SEND_BUNDLE
      first_response = mock_response(status: ReactOnRailsPro::STATUS_SEND_BUNDLE, chunks: ["Bundle not found\n"])

      # Second request for /upload-assets
      upload_response = mock_response(status: 200, chunks: ["Assets uploaded\n"])

      # Third request returns success
      success_response = mock_response(status: 200, chunks: ["Hello, world!\n"])

      request_paths = []
      request_bodies = []

      allow(described_class).to receive(:create_connection).and_return([mock_client, mock_endpoint])
      described_class.instance_variable_set(:@client, mock_client)
      described_class.instance_variable_set(:@endpoint, mock_endpoint)

      call_count = 0
      responses = [first_response, upload_response, success_response]
      allow(mock_client).to receive(:post) do |path, _headers, body|
        request_paths << path
        # Capture body content
        if body.respond_to?(:each)
          body_parts = []
          body.each { |part| body_parts << part }
          request_bodies << body_parts.join
        else
          request_bodies << body.to_s
        end
        response = responses[call_count]
        call_count += 1
        response
      end

      stream = described_class.render_code_as_stream("/render", "console.log('Hello, world!');", is_rsc_payload: false)
      chunks = []
      stream.each_chunk do |chunk|
        chunks << chunk
      end
      expect(chunks).to eq(["Hello, world!"])

      # Verify request sequence
      expect(request_paths).to eq(["/render", "/upload-assets", "/render"])

      # First request should not have a bundle
      expect(request_bodies[0]).to include("renderingRequest=console.log")
      expect(request_bodies[0]).not_to include("bundle")

      # The bundle should be sent via the /upload-assets endpoint
      expect(request_bodies[1]).to include("bundle_server_bundle.js")
      expect(request_bodies[1]).to include('console.log("mock bundle");')

      # Third render request should also not have a bundle
      expect(request_bodies[2]).to include("renderingRequest=console.log")
      expect(request_bodies[2]).not_to include("bundle")
    end

    it "raises duplicate bundle upload error when server asks for bundle twice" do
      # First request returns STATUS_SEND_BUNDLE
      first_response = mock_response(status: ReactOnRailsPro::STATUS_SEND_BUNDLE, chunks: ["Bundle not found\n"])

      # Upload succeeds
      upload_response = mock_response(status: 200, chunks: ["Assets uploaded\n"])

      # Second render request also returns STATUS_SEND_BUNDLE
      second_response = mock_response(status: ReactOnRailsPro::STATUS_SEND_BUNDLE, chunks: ["Bundle still not found\n"])

      responses = [first_response, upload_response, second_response]

      allow(described_class).to receive(:create_connection).and_return([mock_client, mock_endpoint])
      described_class.instance_variable_set(:@client, mock_client)
      described_class.instance_variable_set(:@endpoint, mock_endpoint)

      call_count = 0
      allow(mock_client).to receive(:post) do |_path, _headers, _body|
        response = responses[call_count]
        call_count += 1
        response
      end

      stream = described_class.render_code_as_stream("/render", "console.log('Hello, world!');", is_rsc_payload: false)
      expect do
        stream.each_chunk { |_chunk| nil }
      end.to raise_error(ReactOnRailsPro::Error, /The bundle has already been uploaded/)
    end

    it "raises incompatible error when server returns incompatible error" do
      stub_client_with_responses(
        mock_response(status: ReactOnRailsPro::STATUS_INCOMPATIBLE, chunks: ["Incompatible error"])
      )

      stream = described_class.render_code_as_stream("/render", "console.log('Hello, world!');", is_rsc_payload: false)
      expect do
        stream.each_chunk { |_chunk| nil }
      end.to raise_error(ReactOnRailsPro::Error, /Incompatible error/)
    end

    (400..499).step(20).each do |status_code|
      it "raises an error when server returns error with status code #{status_code}" do
        stub_client_with_responses(mock_response(status: status_code, chunks: ["Unknown error message"]))

        stream = described_class.render_code_as_stream("/render", "console.log('Hello, world!');",
                                                       is_rsc_payload: false)
        expect do
          stream.each_chunk { |_chunk| nil }
        end.to raise_error(ReactOnRailsPro::Error, /#{status_code}:\nUnknown error message/)
      end
    end
  end

  describe "thread-safe connection management" do
    let(:mock_connection) { instance_double(Async::HTTP::Client) }

    before do
      # Reset connection state before each test
      described_class.instance_variable_set(:@client, nil)
      described_class.instance_variable_set(:@endpoint, nil)
    end

    after do
      # Clean up connection state after each test
      described_class.instance_variable_set(:@client, nil)
      described_class.instance_variable_set(:@endpoint, nil)
    end

    it "creates only one connection when accessed concurrently" do
      connections_created = 0
      counter_mutex = Mutex.new

      # Stub create_connection to track calls and simulate slow creation
      allow(described_class).to receive(:create_connection) do
        counter_mutex.synchronize { connections_created += 1 }
        sleep(0.01) # Simulate connection setup time to increase race window
        [mock_connection, mock_endpoint]
      end

      # Simulate multiple threads racing to initialize connection
      threads = Array.new(10) do
        Thread.new { described_class.send(:client) }
      end
      threads.each(&:join)

      # Should only create ONE connection despite concurrent calls
      expect(connections_created).to eq(1)
    end

    it "safely handles reset during concurrent access" do
      allow(described_class).to receive(:create_connection).and_return([mock_connection, mock_endpoint])
      allow(mock_connection).to receive(:close)

      errors = []
      errors_mutex = Mutex.new

      # Background threads accessing connection
      threads = Array.new(5) do
        Thread.new do
          50.times do
            described_class.send(:client)
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
      old_connection = instance_double(Async::HTTP::Client)
      new_connection = instance_double(Async::HTTP::Client)

      # Set up initial connection
      described_class.instance_variable_set(:@client, old_connection)

      allow(described_class).to receive(:create_connection).and_return([new_connection, mock_endpoint])
      expect(old_connection).to receive(:close)

      described_class.reset_connection

      expect(described_class.send(:client)).to eq(new_connection)
    end

    it "propagates close errors during reset" do
      old_connection = instance_double(Async::HTTP::Client)
      new_connection = instance_double(Async::HTTP::Client)

      described_class.instance_variable_set(:@client, old_connection)

      allow(described_class).to receive(:create_connection).and_return([new_connection, mock_endpoint])
      allow(old_connection).to receive(:close).and_raise(StandardError, "Close failed")

      # Should raise the close error
      expect { described_class.reset_connection }.to raise_error(StandardError, "Close failed")

      # But new connection should still be set (close happens after assignment)
      expect(described_class.send(:client)).to eq(new_connection)
    end
  end

  describe "render_code_with_incremental_updates" do
    let(:js_code) { "console.log('incremental rendering');" }
    let(:async_props_block) { proc { |_emitter| } }

    before do
      # Reset connection state before each test
      described_class.instance_variable_set(:@client, nil)
      described_class.instance_variable_set(:@endpoint, nil)

      allow(ReactOnRailsPro::ServerRenderingPool::NodeRenderingPool).to receive_messages(
        server_bundle_hash: "server_bundle.js",
        rsc_bundle_hash: "rsc_bundle.js"
      )

      allow(described_class).to receive(:create_connection).and_return([mock_client, mock_endpoint])
      described_class.instance_variable_set(:@client, mock_client)
      described_class.instance_variable_set(:@endpoint, mock_endpoint)

      # Default mock response
      mock_body = instance_double(Protocol::HTTP::Body::Readable)
      allow(mock_body).to receive(:each).and_yield("chunk\n")
      allow(mock_body).to receive(:close)

      response = instance_double(Protocol::HTTP::Response, status: 200, body: mock_body)
      allow(response).to receive(:read).and_return("")

      allow(mock_client).to receive(:post).and_return(response)

      # Stub AsyncPropsEmitter to return a mock with end_stream_chunk
      allow(ReactOnRailsPro::AsyncPropsEmitter).to receive(:new) do |bundle_timestamp, _request|
        instance_double(
          ReactOnRailsPro::AsyncPropsEmitter,
          end_stream_chunk: { bundleTimestamp: bundle_timestamp, updateChunk: "mocked_js" }
        )
      end
    end

    after do
      # Clean up connection state after each test
      described_class.instance_variable_set(:@client, nil)
      described_class.instance_variable_set(:@endpoint, nil)
    end

    it "creates NDJSON request with correct content type" do
      stream = described_class.render_code_with_incremental_updates(
        "/render-incremental",
        js_code,
        async_props_block: async_props_block
      )

      stream.each_chunk(&:itself)

      expect(mock_client).to have_received(:post).with(
        "/render-incremental",
        satisfy { |headers| headers["content-type"] == "application/x-ndjson" },
        instance_of(Async::HTTP::Body::Writable)
      )
    end

    it "passes AsyncPropsEmitter to async_props_block" do
      emitter_received = nil
      test_async_props_block = proc { |emitter| emitter_received = emitter }

      # Allow real emitter to be created for this test
      allow(ReactOnRailsPro::AsyncPropsEmitter).to receive(:new).and_call_original

      stream = described_class.render_code_with_incremental_updates(
        "/render-incremental",
        js_code,
        async_props_block: test_async_props_block
      )

      stream.each_chunk(&:itself)

      expect(emitter_received).to be_a(ReactOnRailsPro::AsyncPropsEmitter)
    end

    it "executes async_props_block concurrently with response streaming via barrier.async" do
      execution_order = []

      test_async_props_block = proc do |_emitter|
        execution_order << :async_block_start
        # Simulate async work - this runs in a separate fiber
        sleep 0.01
        execution_order << :async_block_end
      end

      # Track when chunks are yielded during streaming
      mock_body = instance_double(Protocol::HTTP::Body::Readable)
      allow(mock_body).to receive(:each) do |&block|
        execution_order << :chunk_yielded
        block.call("chunk\n")
      end
      allow(mock_body).to receive(:close)

      response = instance_double(Protocol::HTTP::Response, status: 200, body: mock_body)
      allow(response).to receive(:read).and_return("")

      allow(mock_client).to receive(:post).and_return(response)

      # Allow real emitter to be created for this test
      allow(ReactOnRailsPro::AsyncPropsEmitter).to receive(:new).and_call_original

      stream = described_class.render_code_with_incremental_updates(
        "/render-incremental",
        js_code,
        async_props_block: test_async_props_block
      )

      stream.each_chunk(&:itself)

      # Verify concurrent execution: chunk should be yielded while async block is running
      # If synchronous, order would be [:async_block_start, :async_block_end, :chunk_yielded]
      expect(execution_order).to eq(%i[async_block_start chunk_yielded async_block_end])
    end

    it "uses rsc_bundle_hash for the AsyncPropsEmitter" do
      allow(ReactOnRailsPro.configuration).to receive(:enable_rsc_support).and_return(true)

      emitter_captured = nil
      allow(ReactOnRailsPro::AsyncPropsEmitter).to receive(:new) do |bundle_timestamp, request_stream|
        emitter_captured = { bundle_timestamp: bundle_timestamp, request_stream: request_stream }
        instance_double(
          ReactOnRailsPro::AsyncPropsEmitter,
          end_stream_chunk: { bundleTimestamp: bundle_timestamp, updateChunk: "mocked_js" }
        )
      end

      stream = described_class.render_code_with_incremental_updates(
        "/render-incremental",
        js_code,
        async_props_block: async_props_block
      )

      stream.each_chunk(&:itself)

      expect(emitter_captured[:bundle_timestamp]).to eq("rsc_bundle.js")
    end
  end
end

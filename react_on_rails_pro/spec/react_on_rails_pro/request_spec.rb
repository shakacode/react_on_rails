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

    original_httpx_plugin = HTTPX.method(:plugin)
    allow(HTTPX).to receive(:plugin) do |*args|
      original_httpx_plugin.call(:mock_stream).plugin(*args)
    end
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

    [true, false].each do |use_delay|
      it "processes each chunk immediately when use_delay is #{use_delay}" do
        mocked_block = mock_block

        mock_streaming_response(render_full_url, 200) do |yielder|
          sleep(0.2) if use_delay
          yielder.call("First chunk\n")
          expect(mocked_block).to have_received(:call).with("First chunk")

          sleep(0.2) if use_delay
          yielder.call("Second chunk\n  ")
          expect(mocked_block).to have_received(:call).with("Second chunk")

          sleep(0.2) if use_delay
          yielder.call("Final chunk\n")
          expect(mocked_block).to have_received(:call).with("Final chunk")
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
        yielder.call("Hello, world!\n")
      end

      stream = described_class.render_code_as_stream("/render", "console.log('Hello, world!');", is_rsc_payload: false)
      chunks = []
      stream.each_chunk do |chunk|
        chunks << chunk
      end
      expect(chunks).to eq(["Hello, world!"])

      # First request should not have a bundle
      expect(first_request_info[:request].body.to_s).to include("renderingRequest=console.log")
      expect(first_request_info[:request].body.to_s).not_to include("bundle")

      # Second request should have a bundle
      # It's a multipart/form-data request, so we can access the form directly
      second_request_body = second_request_info[:request].body.instance_variable_get(:@body)
      second_request_form = second_request_body.instance_variable_get(:@form)

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
      second_request_body = second_request_info[:request].body.instance_variable_get(:@body)
      second_request_form = second_request_body.instance_variable_get(:@form)

      expect(second_request_form).to have_key("bundle_server_bundle.js")
      expect(second_request_form["bundle_server_bundle.js"][:body]).to be_a(FakeFS::Pathname)
      expect(second_request_form["bundle_server_bundle.js"][:body].to_s).to eq(server_bundle_path)
    end

    it "raises incompatible error when server returns incompatible error" do
      mocked_block = mock_block

      mock_streaming_response(render_full_url, ReactOnRailsPro::STATUS_INCOMPATIBLE) do |yielder|
        yielder.call("Incompatible error")
      end

      stream = described_class.render_code_as_stream("/render", "console.log('Hello, world!');", is_rsc_payload: false)
      expect do
        stream.each_chunk(&mocked_block.block)
      end.to raise_error(ReactOnRailsPro::Error, /Incompatible error/)

      expect(mocked_block).not_to have_received(:call)
    end

    (400..499).step(20).each do |status_code|
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
  end

  describe "thread-safe connection management" do
    let(:mock_connection) { instance_double(HTTPX::Session) }

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
      old_connection = instance_double(HTTPX::Session)
      new_connection = instance_double(HTTPX::Session)

      # Set up initial connection
      described_class.instance_variable_set(:@connection, old_connection)

      allow(described_class).to receive(:create_connection).and_return(new_connection)
      expect(old_connection).to receive(:close)

      described_class.reset_connection

      expect(described_class.send(:connection)).to eq(new_connection)
    end

    it "propagates close errors during reset" do
      old_connection = instance_double(HTTPX::Session)
      new_connection = instance_double(HTTPX::Session)

      described_class.instance_variable_set(:@connection, old_connection)

      allow(described_class).to receive(:create_connection).and_return(new_connection)
      allow(old_connection).to receive(:close).and_raise(StandardError, "Close failed")

      # Should raise the close error
      expect { described_class.reset_connection }.to raise_error(StandardError, "Close failed")

      # But new connection should still be set (close happens after assignment)
      expect(described_class.send(:connection)).to eq(new_connection)
    end
  end
end

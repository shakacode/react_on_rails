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

    allow(ReactOnRails::Utils).to receive_messages(server_bundle_js_file_path: server_bundle_path,
                                                   rsc_bundle_js_file_path: rsc_server_bundle_path)
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
end

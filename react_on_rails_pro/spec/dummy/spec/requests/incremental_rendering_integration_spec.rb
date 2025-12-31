# frozen_string_literal: true

require "rails_helper"

# Integration tests for incremental rendering with bidirectional streaming
#
# IMPORTANT: These tests require a running node-renderer server.
# Before running these tests:
#   1. cd packages/node-renderer
#   2. yarn test:setup  # or equivalent command to start the test server
#   3. Keep the server running in a separate terminal
#
# Then run these tests:
#   bundle exec rspec spec/requests/incremental_rendering_integration_spec.rb
#
describe "Incremental Rendering Integration", :integration do
  let(:server_bundle_hash) { "test_incremental_bundle" }
  # Fixture bundle paths (real files on disk)
  let(:fixture_bundle_path) do
    File.expand_path(
      "../../../../../packages/react-on-rails-pro-node-renderer/tests/fixtures/bundle-incremental.js",
      __dir__
    )
  end
  let(:fixture_rsc_bundle_path) do
    File.expand_path(
      "../../../../../packages/react-on-rails-pro-node-renderer/tests/fixtures/secondary-bundle-incremental.js",
      __dir__
    )
  end
  let(:rsc_bundle_hash) { "test_incremental_rsc_bundle" }

  before do
    allow(ReactOnRailsPro::ServerRenderingPool::NodeRenderingPool).to receive_messages(
      server_bundle_hash: server_bundle_hash,
      rsc_bundle_hash: rsc_bundle_hash,
      renderer_bundle_file_name: "#{server_bundle_hash}.js",
      rsc_renderer_bundle_file_name: "#{rsc_bundle_hash}.js"
    )

    # Enable RSC support for these tests
    allow(ReactOnRailsPro.configuration).to receive(:enable_rsc_support).and_return(true)

    # Mock populate_form_with_bundle_and_assets to use fixture bundles directly
    # rubocop:disable Lint/UnusedBlockArgument
    allow(ReactOnRailsPro::Request).to receive(:populate_form_with_bundle_and_assets) do |form, check_bundle:|
      # rubocop:enable Lint/UnusedBlockArgument
      form["bundle_#{server_bundle_hash}"] = {
        body: Pathname.new(fixture_bundle_path),
        content_type: "text/javascript",
        filename: "#{server_bundle_hash}.js"
      }

      form["bundle_#{rsc_bundle_hash}"] = {
        body: Pathname.new(fixture_rsc_bundle_path),
        content_type: "text/javascript",
        filename: "#{rsc_bundle_hash}.js"
      }
    end

    # Mock AsyncPropsEmitter chunk generation methods to work with fixture bundles
    # Only mock the chunk generation, not the actual call/streaming logic
    # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(ReactOnRailsPro::AsyncPropsEmitter)
      .to receive(:generate_update_chunk) do |emitter, _prop_name, value|
        bundle_timestamp = emitter.instance_variable_get(:@bundle_timestamp)
        {
          bundleTimestamp: bundle_timestamp,
          # Add newline to the value so the fixture bundle writes it with newline
          updateChunk: "ReactOnRails.addStreamValue(#{value.to_json} + '\\n')"
        }
      end

    allow_any_instance_of(ReactOnRailsPro::AsyncPropsEmitter).to receive(:end_stream_chunk).and_call_original
    allow_any_instance_of(ReactOnRailsPro::AsyncPropsEmitter).to receive(:generate_end_stream_js).and_return(
      "ReactOnRails.endStream()"
    )
    # rubocop:enable RSpec/AnyInstance

    # Reset any existing connections to ensure clean state
    ReactOnRailsPro::Request.reset_connection
  end

  after do
    ReactOnRailsPro::Request.reset_connection
  end

  describe "upload_assets" do
    it "successfully uploads fixture bundles to the node renderer" do
      expect do
        ReactOnRailsPro::Request.upload_assets
      end.not_to raise_error
    end
  end

  describe "render_code" do
    it "renders simple non-streaming request using ReactOnRails.dummy" do
      # Upload bundles first
      ReactOnRailsPro::Request.upload_assets

      # Construct the render path: /bundles/:bundleTimestamp/render/:renderRequestDigest
      js_code = "ReactOnRails.dummy"
      request_digest = Digest::MD5.hexdigest(js_code)
      render_path = "/bundles/#{server_bundle_hash}/render/#{request_digest}"

      # Render using the fixture bundle
      response = ReactOnRailsPro::Request.render_code(render_path, js_code, false)

      expect(response.status).to eq(200)
      expect(response.body.to_s).to include("Dummy Object")
    end
  end

  describe "render_code_with_incremental_updates" do
    it "sends stream values and receives them in the response" do
      # Upload bundles first
      ReactOnRailsPro::Request.upload_assets

      # Construct the incremental render path
      js_code = "ReactOnRails.getStreamValues()"
      request_digest = Digest::MD5.hexdigest(js_code)
      render_path = "/bundles/#{server_bundle_hash}/incremental-render/#{request_digest}"

      # Perform incremental rendering with stream updates
      stream = ReactOnRailsPro::Request.render_code_with_incremental_updates(
        render_path,
        js_code,
        async_props_block: proc { |emitter|
          emitter.call("prop1", "value1")
          emitter.call("prop2", "value2")
          emitter.call("prop3", "value3")
        },
        is_rsc_payload: false
      )

      # Collect all chunks from the stream
      chunks = []
      stream.each_chunk do |chunk|
        chunks << chunk
      end

      # Verify we received all the values
      response_text = chunks.join
      expect(response_text).to include("value1")
      expect(response_text).to include("value2")
      expect(response_text).to include("value3")
    end

    it "streams bidirectionally - each_chunk receives chunks while async_props_block is still running" do
      # Upload bundles first
      ReactOnRailsPro::Request.upload_assets

      # Construct the incremental render path
      js_code = "ReactOnRails.getStreamValues()"
      request_digest = Digest::MD5.hexdigest(js_code)
      render_path = "/bundles/#{server_bundle_hash}/incremental-render/#{request_digest}"

      # Single condition to signal when each chunk is received
      chunk_received = Async::Condition.new

      # Wrap the test in a timeout to prevent hanging forever on deadlock
      Timeout.timeout(10) do
        # Perform incremental rendering with bidirectional verification
        stream = ReactOnRailsPro::Request.render_code_with_incremental_updates(
          render_path,
          js_code,
          async_props_block: proc { |emitter|
            # Send first value and wait for confirmation
            emitter.call("prop1", "value1")
            chunk_received.wait

            # Send second value and wait for confirmation
            emitter.call("prop2", "value2")
            chunk_received.wait

            # Send third value and wait for confirmation
            emitter.call("prop3", "value3")
            chunk_received.wait

            # If we reach here, all chunks were received while async_block was running
          },
          is_rsc_payload: false
        )

        # Collect chunks and signal after each one
        chunks = []
        stream.each_chunk do |chunk|
          chunks << chunk
          chunk_received.signal
        end

        # Verify all values were received
        response_text = chunks.join
        expect(response_text).to include("value1")
        expect(response_text).to include("value2")
        expect(response_text).to include("value3")

        # If this test completes without deadlock, it proves bidirectional streaming:
        # - async_props_block sent chunks and waited for confirmation
        # - each_chunk received chunks and signaled back while async_props_block was still running
        # - This would deadlock if chunks weren't received concurrently
      end
    end
  end
end

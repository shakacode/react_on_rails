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

    # Point bundle path methods to fixture files so upload_assets finds them
    allow(ReactOnRails::Utils).to receive(:server_bundle_js_file_path).and_return(fixture_bundle_path)
    allow(ReactOnRailsPro::Utils).to receive(:rsc_bundle_js_file_path).and_return(fixture_rsc_bundle_path)

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

    # Mock AsyncPropsEmitter chunk generation methods to work with fixture bundles.
    # The fixture's addStreamValueToFirstBundle writes raw text to a PassThrough stream
    # that is piped directly to the HTTP response. Ruby's LengthPrefixedParser expects
    # the wire format: <metadata JSON>\t<8-char hex length>\n<content>.
    # So we build the LPP frame in the updateChunk JS itself.
    # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(ReactOnRailsPro::AsyncPropsEmitter)
      .to receive(:generate_update_chunk) do |emitter, _prop_name, value|
        bundle_timestamp = emitter.instance_variable_get(:@bundle_timestamp)
        json_value = value.to_json
        {
          bundleTimestamp: bundle_timestamp,
          updateChunk: <<~JS.chomp
            (function() {
              var content = #{json_value};
              var meta = JSON.stringify({consoleReplayScript:"",hasErrors:false,isShellReady:true,payloadType:"string"});
              var len = Buffer.byteLength(content, "utf8").toString(16).padStart(8, "0");
              ReactOnRails.addStreamValueToFirstBundle(meta + "\\t" + len + "\\n" + content);
            })()
          JS
        }
      end

    allow_any_instance_of(ReactOnRailsPro::AsyncPropsEmitter).to receive(:end_stream_chunk).and_call_original
    allow_any_instance_of(ReactOnRailsPro::AsyncPropsEmitter).to receive(:generate_end_stream_js).and_return(
      "ReactOnRails.endFirstBundleStream()"
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
        }
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
          }
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

    context "when an update chunk contains invalid JavaScript" do
      before do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(ReactOnRailsPro::AsyncPropsEmitter)
          .to receive(:generate_update_chunk) do |emitter, prop_name, value|
            bundle_timestamp = emitter.instance_variable_get(:@bundle_timestamp)

            if prop_name == "bad_prop"
              # Emit syntactically invalid JS that will throw in the VM
              {
                bundleTimestamp: bundle_timestamp,
                updateChunk: "this is not valid javascript @@!#$%"
              }
            else
              json_value = value.to_json
              {
                bundleTimestamp: bundle_timestamp,
                updateChunk: <<~JS.chomp
                  (function() {
                    var content = #{json_value};
                    var meta = JSON.stringify({consoleReplayScript:"",hasErrors:false,isShellReady:true,payloadType:"string"});
                    var len = Buffer.byteLength(content, "utf8").toString(16).padStart(8, "0");
                    ReactOnRails.addStreamValueToFirstBundle(meta + "\\t" + len + "\\n" + content);
                  })()
                JS
              }
            end
          end
        # rubocop:enable RSpec/AnyInstance
      end

      it "continues streaming valid props when one update chunk has invalid JS" do
        ReactOnRailsPro::Request.upload_assets

        js_code = "ReactOnRails.getStreamValues()"
        request_digest = Digest::MD5.hexdigest(js_code)
        render_path = "/bundles/#{server_bundle_hash}/incremental-render/#{request_digest}"

        Timeout.timeout(10) do
          stream = ReactOnRailsPro::Request.render_code_with_incremental_updates(
            render_path,
            js_code,
            async_props_block: proc { |emitter|
              emitter.call("good_prop1", "hello")
              emitter.call("bad_prop", "this_wont_arrive")
              emitter.call("good_prop2", "world")
            }
          )

          chunks = []
          stream.each_chunk do |chunk|
            chunks << chunk
          end

          response_text = chunks.join
          expect(response_text).to include("hello")
          expect(response_text).to include("world")
          # The bad_prop value never arrives because the JS that would have
          # written it to the stream was invalid and threw in the VM
          expect(response_text).not_to include("this_wont_arrive")
        end
      end
    end

    context "when async_props_block raises an exception" do
      it "closes the stream and propagates the error" do
        ReactOnRailsPro::Request.upload_assets

        js_code = "ReactOnRails.getStreamValues()"
        request_digest = Digest::MD5.hexdigest(js_code)
        render_path = "/bundles/#{server_bundle_hash}/incremental-render/#{request_digest}"

        Timeout.timeout(10) do
          stream = ReactOnRailsPro::Request.render_code_with_incremental_updates(
            render_path,
            js_code,
            async_props_block: proc { |emitter|
              emitter.call("prop1", "before_error")
              raise StandardError, "something went wrong in the async block"
            }
          )

          # barrier.wait re-raises the exception from the async task
          expect do
            stream.each_chunk { |_chunk| }
          end.to raise_error(StandardError, "something went wrong in the async block")
        end
      end
    end

    context "when rendering request JS is invalid" do
      it "raises ReactOnRailsPro::Error with the exception details" do
        ReactOnRailsPro::Request.upload_assets

        js_code = "this is not valid javascript @@!#$%"
        request_digest = Digest::MD5.hexdigest(js_code)
        render_path = "/bundles/#{server_bundle_hash}/incremental-render/#{request_digest}"

        Timeout.timeout(10) do
          stream = ReactOnRailsPro::Request.render_code_with_incremental_updates(
            render_path,
            js_code,
            async_props_block: proc { |_emitter| }
          )

          expect do
            stream.each_chunk { |_chunk| }
          end.to raise_error(ReactOnRailsPro::Error, /Unexpected identifier/)
        end
      end
    end

    context "when bundle is not found (410 retry)" do
      it "re-uploads the bundle and retries successfully" do
        # Use a unique bundle hash that the Node renderer hasn't seen yet.
        # This triggers a 410 on the first request, then retry uploads and succeeds.
        unique_hash = "retry_test_#{SecureRandom.hex(8)}"
        allow(ReactOnRailsPro::ServerRenderingPool::NodeRenderingPool)
          .to receive(:server_bundle_hash).and_return(unique_hash)
        allow(ReactOnRailsPro::ServerRenderingPool::NodeRenderingPool)
          .to receive(:renderer_bundle_file_name).and_return("#{unique_hash}.js")

        # Update populate_form to use unique hash keys
        # rubocop:disable Lint/UnusedBlockArgument
        allow(ReactOnRailsPro::Request).to receive(:populate_form_with_bundle_and_assets) do |form, check_bundle:|
          # rubocop:enable Lint/UnusedBlockArgument
          form["bundle_#{unique_hash}"] = {
            body: Pathname.new(fixture_bundle_path),
            content_type: "text/javascript",
            filename: "#{unique_hash}.js"
          }
          form["bundle_#{rsc_bundle_hash}"] = {
            body: Pathname.new(fixture_rsc_bundle_path),
            content_type: "text/javascript",
            filename: "#{rsc_bundle_hash}.js"
          }
        end

        # Do NOT call upload_assets — the bundle isn't on the renderer yet
        js_code = "ReactOnRails.dummy"
        request_digest = Digest::MD5.hexdigest(js_code)
        render_path = "/bundles/#{unique_hash}/render/#{request_digest}"

        Timeout.timeout(10) do
          response = ReactOnRailsPro::Request.render_code(render_path, js_code, false)

          expect(response.status).to eq(200)
          expect(response.body.to_s).to include("Dummy Object")
        end
      end

      it "re-uploads the bundle and retries incremental render successfully" do
        unique_hash = "retry_incr_#{SecureRandom.hex(8)}"
        allow(ReactOnRailsPro::ServerRenderingPool::NodeRenderingPool)
          .to receive(:server_bundle_hash).and_return(unique_hash)
        allow(ReactOnRailsPro::ServerRenderingPool::NodeRenderingPool)
          .to receive(:renderer_bundle_file_name).and_return("#{unique_hash}.js")

        # rubocop:disable Lint/UnusedBlockArgument
        allow(ReactOnRailsPro::Request).to receive(:populate_form_with_bundle_and_assets) do |form, check_bundle:|
          # rubocop:enable Lint/UnusedBlockArgument
          form["bundle_#{unique_hash}"] = {
            body: Pathname.new(fixture_bundle_path),
            content_type: "text/javascript",
            filename: "#{unique_hash}.js"
          }
          form["bundle_#{rsc_bundle_hash}"] = {
            body: Pathname.new(fixture_rsc_bundle_path),
            content_type: "text/javascript",
            filename: "#{rsc_bundle_hash}.js"
          }
        end

        js_code = "ReactOnRails.getStreamValues()"
        request_digest = Digest::MD5.hexdigest(js_code)
        render_path = "/bundles/#{unique_hash}/incremental-render/#{request_digest}"

        Timeout.timeout(10) do
          stream = ReactOnRailsPro::Request.render_code_with_incremental_updates(
            render_path,
            js_code,
            async_props_block: proc { |emitter|
              emitter.call("retry_prop", "retry_success")
            }
          )

          chunks = []
          stream.each_chunk { |chunk| chunks << chunk }
          response_text = chunks.join
          expect(response_text).to include("retry_success")
        end
      end
    end

    context "with large payloads exceeding HTTP/2 frame size" do
      it "streams a payload larger than 16KB correctly" do
        ReactOnRailsPro::Request.upload_assets

        js_code = "ReactOnRails.getStreamValues()"
        request_digest = Digest::MD5.hexdigest(js_code)
        render_path = "/bundles/#{server_bundle_hash}/incremental-render/#{request_digest}"

        # Generate a payload larger than default HTTP/2 frame size (16KB)
        large_value = "X" * 20_000

        Timeout.timeout(10) do
          stream = ReactOnRailsPro::Request.render_code_with_incremental_updates(
            render_path,
            js_code,
            async_props_block: proc { |emitter|
              emitter.call("large_prop", large_value)
            }
          )

          chunks = []
          stream.each_chunk { |chunk| chunks << chunk }
          response_text = chunks.join
          expect(response_text).to include(large_value)
        end
      end

      it "streams multiple large payloads without corruption" do
        ReactOnRailsPro::Request.upload_assets

        js_code = "ReactOnRails.getStreamValues()"
        request_digest = Digest::MD5.hexdigest(js_code)
        render_path = "/bundles/#{server_bundle_hash}/incremental-render/#{request_digest}"

        values = 3.times.map { |i| "PAYLOAD_#{i}_#{'Y' * 18_000}" }

        Timeout.timeout(15) do
          stream = ReactOnRailsPro::Request.render_code_with_incremental_updates(
            render_path,
            js_code,
            async_props_block: proc { |emitter|
              values.each_with_index { |val, i| emitter.call("prop_#{i}", val) }
            }
          )

          chunks = []
          stream.each_chunk { |chunk| chunks << chunk }
          response_text = chunks.join
          values.each { |val| expect(response_text).to include(val) }
        end
      end
    end

    context "with concurrent incremental render requests" do
      it "handles multiple parallel streams without interference" do
        ReactOnRailsPro::Request.upload_assets

        js_code = "ReactOnRails.getStreamValues()"
        request_digest = Digest::MD5.hexdigest(js_code)
        render_path = "/bundles/#{server_bundle_hash}/incremental-render/#{request_digest}"

        results = Array.new(3)

        Timeout.timeout(15) do
          Sync do
            3.times.map do |i|
              Async do
                stream = ReactOnRailsPro::Request.render_code_with_incremental_updates(
                  render_path,
                  js_code,
                  async_props_block: proc { |emitter|
                    emitter.call("stream_id", "stream_#{i}_data")
                  }
                )

                chunks = []
                stream.each_chunk { |chunk| chunks << chunk }
                results[i] = chunks.join
              end
            end.each(&:wait)
          end
        end

        # Each stream should have received its own data without cross-contamination
        3.times do |i|
          expect(results[i]).to include("stream_#{i}_data")
          # Verify no data from other streams leaked in
          other_indices = [0, 1, 2] - [i]
          other_indices.each do |j|
            expect(results[i]).not_to include("stream_#{j}_data")
          end
        end
      end
    end

    context "when error scenarios repeat without connection reset" do
      let(:js_code) { "ReactOnRails.getStreamValues()" }
      let(:render_path) do
        "/bundles/#{server_bundle_hash}/incremental-render/#{Digest::MD5.hexdigest(js_code)}"
      end

      def perform_successful_stream_request
        stream = ReactOnRailsPro::Request.render_code_with_incremental_updates(
          render_path,
          js_code,
          async_props_block: proc { |emitter|
            emitter.call("verify_prop", "connection_ok")
          }
        )

        chunks = []
        stream.each_chunk { |chunk| chunks << chunk }
        response_text = chunks.join
        expect(response_text).to include("connection_ok")
      end

      it "does not exhaust the connection pool after repeated invalid JS chunks" do
        # Override to emit invalid JS for "bad" prop
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(ReactOnRailsPro::AsyncPropsEmitter)
          .to receive(:generate_update_chunk) do |emitter, prop_name, value|
            bundle_timestamp = emitter.instance_variable_get(:@bundle_timestamp)

            if prop_name == "bad"
              { bundleTimestamp: bundle_timestamp, updateChunk: "invalid js @@!!" }
            else
              json_value = value.to_json
              {
                bundleTimestamp: bundle_timestamp,
                updateChunk: <<~JS.chomp
                  (function() {
                    var content = #{json_value};
                    var meta = JSON.stringify({consoleReplayScript:"",hasErrors:false,isShellReady:true,payloadType:"string"});
                    var len = Buffer.byteLength(content, "utf8").toString(16).padStart(8, "0");
                    ReactOnRails.addStreamValueToFirstBundle(meta + "\\t" + len + "\\n" + content);
                  })()
                JS
              }
            end
          end
        # rubocop:enable RSpec/AnyInstance

        ReactOnRailsPro::Request.upload_assets

        Timeout.timeout(30) do
          10.times do
            stream = ReactOnRailsPro::Request.render_code_with_incremental_updates(
              render_path,
              js_code,
              async_props_block: proc { |emitter|
                emitter.call("good", "ok")
                emitter.call("bad", "fail")
                emitter.call("good2", "ok2")
              }
            )

            chunks = []
            stream.each_chunk { |chunk| chunks << chunk }
            response_text = chunks.join
            expect(response_text).to include("ok")
            expect(response_text).to include("ok2")
            expect(response_text).not_to include("fail")
          end

          perform_successful_stream_request
        end
      end

      it "does not exhaust the connection pool after repeated async_props_block exceptions" do
        ReactOnRailsPro::Request.upload_assets

        Timeout.timeout(30) do
          10.times do |i|
            stream = ReactOnRailsPro::Request.render_code_with_incremental_updates(
              render_path,
              js_code,
              async_props_block: proc { |emitter|
                emitter.call("prop", "value_#{i}")
                raise StandardError, "repeated failure #{i}"
              }
            )

            expect do
              stream.each_chunk { |_chunk| }
            end.to raise_error(StandardError, "repeated failure #{i}")
          end

          perform_successful_stream_request
        end
      end

      it "does not exhaust the connection pool after repeated invalid rendering requests" do
        ReactOnRailsPro::Request.upload_assets

        Timeout.timeout(30) do
          10.times do |i|
            invalid_js = "not valid js @@#{i}"
            digest = Digest::MD5.hexdigest(invalid_js)
            path = "/bundles/#{server_bundle_hash}/incremental-render/#{digest}"

            stream = ReactOnRailsPro::Request.render_code_with_incremental_updates(
              path,
              invalid_js,
              async_props_block: proc { |_emitter| }
            )

            expect do
              stream.each_chunk { |_chunk| }
            end.to raise_error(ReactOnRailsPro::Error, /Unexpected identifier|Unexpected token/)
          end

          perform_successful_stream_request
        end
      end

      it "succeeds with normal requests after mixed error types" do
        ReactOnRailsPro::Request.upload_assets

        Timeout.timeout(30) do
          # Trigger async_props_block exceptions
          3.times do |i|
            stream = ReactOnRailsPro::Request.render_code_with_incremental_updates(
              render_path,
              js_code,
              async_props_block: proc { |_emitter|
                raise StandardError, "async error #{i}"
              }
            )
            expect do
              stream.each_chunk { |_chunk| }
            end.to raise_error(StandardError, "async error #{i}")
          end

          # Trigger invalid rendering request errors
          3.times do |i|
            invalid_js = "syntax error @@#{i}"
            digest = Digest::MD5.hexdigest(invalid_js)
            path = "/bundles/#{server_bundle_hash}/incremental-render/#{digest}"

            stream = ReactOnRailsPro::Request.render_code_with_incremental_updates(
              path,
              invalid_js,
              async_props_block: proc { |_emitter| }
            )
            expect do
              stream.each_chunk { |_chunk| }
            end.to raise_error(ReactOnRailsPro::Error, /Unexpected identifier|Unexpected token/)
          end

          # Verify normal streaming still works after all those errors
          perform_successful_stream_request
        end
      end
    end
  end
end

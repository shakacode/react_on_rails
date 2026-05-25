# frozen_string_literal: true

require_relative "base"
require "digest"

module RendererHarness
  module Scenarios
    # Scenario that performs a bidirectional HTTP/2 streaming render via
    # render_code_with_incremental_updates, emitting async props incrementally.
    #
    # FIXME: This scenario is not yet fully functional against the dummy app's production
    # server bundle. The incremental-render endpoint requires a JS handler that:
    #   1. Accepts async prop chunks via the bidirectional NDJSON stream, AND
    #   2. Renders a component that consumes those props via ReactOnRails.addAsyncPropsCapabilityToComponentProps
    #
    # This capability is only available in the RSC bundle, not the plain server bundle.
    # The integration tests use special fixture bundles
    # (react-on-rails-pro-node-renderer/tests/fixtures/bundle-incremental.js)
    # with a `ReactOnRails.getStreamValues()` helper that does not exist in production bundles.
    #
    # To get this scenario working against a real app, you would need either:
    #   a) A component that calls ReactOnRails.addAsyncPropsCapabilityToComponentProps
    #      (requires running on the RSC bundle with RSC mode enabled), or
    #   b) A test fixture bundle that implements a streaming echo handler
    #
    # See: https://github.com/shakacode/react_on_rails/issues (file a follow-up issue)
    #
    # For now, this scenario is included to exercise the Ruby-side code path and measure
    # the overhead of the incremental-render HTTP/2 handshake. The renderer will return
    # a 400 on JS execution, which the scenario records as a failure. This is expected
    # until a suitable test component or fixture is wired up.
    #
    # Path format: /bundles/:bundleTimestamp/incremental-render/:renderRequestDigest
    # The stream is iterated via StreamDecorator#each_chunk (not #each).
    class IncrementalAsync < Base
      # FIXME: ReactOnRails.getStreamValues() is only available in the node-renderer
      # test fixture bundles, not in the production server bundle. Replace with a
      # real RSC component or fixture when this scenario is properly wired up.
      JS_TEMPLATE = "ReactOnRails.getStreamValues()"

      def initialize(config)
        super
        warn "[incremental_async] WARNING: This scenario is not yet functional against the dummy app " \
             "and will report 100% failures. See the class-level FIXME for details."
      end

      def perform_request
        js = JS_TEMPLATE
        bundle_hash = ReactOnRailsPro::ServerRenderingPool::NodeRenderingPool.server_bundle_hash
        digest = Digest::MD5.hexdigest(js)
        path = "/bundles/#{bundle_hash}/incremental-render/#{digest}"

        measure do
          bytes_in = 0

          stream = ReactOnRailsPro::Request.render_code_with_incremental_updates(
            path,
            js,
            async_props_block: build_async_props_block(config.increments)
          )

          stream.each_chunk do |chunk|
            bytes_in += chunk.bytesize if chunk.respond_to?(:bytesize)
          end
          { http_status: nil, bytes_in: bytes_in, bytes_out: js.bytesize }
        end
      end

      private

      def build_async_props_block(increments)
        props = filler_props
        lambda do |emit|
          increments.times do |i|
            emit.call("chunk_#{i}", { i: i, payload: props })
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

require_relative "base"
require "digest"

module RendererHarness
  module Scenarios
    # Scenario that performs a server-side render via the streaming HTTP transport.
    #
    # The render endpoint /bundles/:hash/render/:digest is the same endpoint used by
    # standard_render, but the HTTP request is made with stream: true so the response
    # body is read chunk-by-chunk. This measures streaming-transport overhead vs.
    # buffered transport (standard_render).
    #
    # We deliberately use serverRenderReactComponent (non-RSC) here because
    # streamServerRenderedReactComponent requires Rails RSC context fields
    # (reactClientManifestFileName etc.) that are not available outside a real Rails request.
    #
    # The stream is iterated via StreamDecorator#each_chunk (not #each).
    class StreamingRender < Base
      JS_TEMPLATE = <<~JS
        (function(){
          var props = %<props>s;
          return ReactOnRails.serverRenderReactComponent({
            name: 'HelloWorld',
            domNodeId: 'HelloWorld-react-component',
            props: props,
            trace: false,
            renderingReturnsPromises: false
          });
        })()
      JS

      def perform_request
        js = format(JS_TEMPLATE, props: filler_props.to_json)
        bundle_hash = ReactOnRailsPro::ServerRenderingPool::NodeRenderingPool.server_bundle_hash
        digest = Digest::MD5.hexdigest(js)
        path = "/bundles/#{bundle_hash}/render/#{digest}"

        measure do
          bytes_in = 0
          stream = ReactOnRailsPro::Request.render_code_as_stream(path, js, is_rsc_payload: false)
          stream.each_chunk do |chunk|
            bytes_in += chunk.bytesize if chunk.respond_to?(:bytesize)
          end
          { http_status: stream_status(stream), bytes_in: bytes_in, bytes_out: js.bytesize }
        end
      end
    end
  end
end

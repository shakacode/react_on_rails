# frozen_string_literal: true

require_relative "base"

module RendererHarness
  module Scenarios
    # Scenario that performs a streaming server-side render via the node renderer.
    class StreamingRender < Base
      JS_TEMPLATE = <<~JS
        (function(){
          var props = %<props>s;
          return ReactOnRails.serverRenderReactComponent({
            name: 'StreamableHelloWorld',
            domNodeId: 'StreamableHelloWorld-react-component',
            props: props,
            trace: false,
            renderingReturnsPromises: true
          });
        })()
      JS

      def perform_request
        js = format(JS_TEMPLATE, props: filler_props.to_json)
        measure do
          bytes_in = 0
          status = nil
          stream = ReactOnRailsPro::Request.render_code_as_stream(
            "/bundles/server-bundle.js/render-stream",
            js,
            is_rsc_payload: false
          )
          stream.each do |chunk|
            bytes_in += chunk.bytesize if chunk.respond_to?(:bytesize)
            status ||= stream.respond_to?(:status) ? stream.status : nil
          end
          { http_status: status, bytes_in: bytes_in, bytes_out: js.bytesize }
        end
      end
    end
  end
end

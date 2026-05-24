# frozen_string_literal: true

require_relative "base"

module RendererHarness
  module Scenarios
    # Scenario that performs a bidirectional HTTP/2 streaming render via
    # render_code_with_incremental_updates, emitting async props incrementally.
    class IncrementalAsync < Base
      JS_TEMPLATE = <<~JS
        (function(){
          var props = %<props>s;
          return ReactOnRails.serverRenderReactComponent({
            name: 'AsyncPropsComponent',
            domNodeId: 'AsyncPropsComponent-react-component',
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

          stream = ReactOnRailsPro::Request.render_code_with_incremental_updates(
            "/bundles/server-bundle.js/render-incremental",
            js,
            async_props_block: build_async_props_block(config.increments)
          )

          stream.each do |chunk|
            bytes_in += chunk.bytesize if chunk.respond_to?(:bytesize)
            status ||= stream.respond_to?(:status) ? stream.status : nil
          end
          { http_status: status, bytes_in: bytes_in, bytes_out: js.bytesize }
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

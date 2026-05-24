# frozen_string_literal: true

require_relative "base"

module RendererHarness
  module Scenarios
    # Scenario that performs a single synchronous server-side render via the node renderer.
    class StandardRender < Base
      JS_TEMPLATE = <<~JS
        (function(){
          var HelloWorld = ReactOnRails.getComponent('HelloWorld');
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
        measure do
          response = ReactOnRailsPro::Request.render_code(
            "/bundles/server-bundle.js/render",
            js,
            false
          )
          body = response.respond_to?(:body) ? response.body.to_s : response.to_s
          {
            http_status: response.respond_to?(:status) ? response.status : nil,
            bytes_in: body.bytesize,
            bytes_out: js.bytesize
          }
        end
      end
    end
  end
end

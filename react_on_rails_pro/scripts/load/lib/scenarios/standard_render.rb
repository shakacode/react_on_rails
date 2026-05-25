# frozen_string_literal: true

require_relative "base"
require "digest"

module RendererHarness
  module Scenarios
    # Scenario that performs a single synchronous server-side render via the node renderer.
    #
    # Uses HelloWorld (registered via auto-load in the dummy app's server-bundle).
    # Path format: /bundles/:bundleTimestamp/render/:renderRequestDigest
    class StandardRender < Base
      def perform_request
        js = format(RENDER_COMPONENT_JS_TEMPLATE, props: filler_props.to_json)
        bundle_hash = server_bundle_hash
        digest = Digest::MD5.hexdigest(js)
        path = "/bundles/#{bundle_hash}/render/#{digest}"

        measure do
          response = ReactOnRailsPro::Request.render_code(path, js, false)
          body = response.respond_to?(:body) ? response.body.to_s : response.to_s
          status = response.respond_to?(:status) ? response.status : nil
          raise "Renderer returned #{status}: #{body.slice(0, 200)}" if status && status >= 400

          {
            http_status: status,
            bytes_in: body.bytesize,
            bytes_out: js.bytesize
          }
        end
      end
    end
  end
end

# frozen_string_literal: true

module ReactOnRailsPro
  module RenderingStrategy
    # Pro rendering strategy wrapping ProRendering, which handles caching,
    # streaming, and the ExecJS vs Node renderer dispatch.
    #
    # Part of the strategy pattern refactoring (see issue #2905).
    # Currently additive — not yet wired into the main rendering path.
    class NodeStrategy
      include ReactOnRails::RenderingStrategy

      def execute(render_request)
        js_code = render_request.to_js
        ReactOnRailsPro::ServerRenderingPool::ProRendering
          .exec_server_render_js(js_code, render_request.render_options)
      end

      def reset
        ReactOnRailsPro::ServerRenderingPool::ProRendering.reset_pool
      end

      def reset_if_bundle_changed
        ReactOnRailsPro::ServerRenderingPool::ProRendering
          .reset_pool_if_server_bundle_was_modified
      end
    end
  end
end

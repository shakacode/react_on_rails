# frozen_string_literal: true

module ReactOnRails
  module RenderingStrategy
    # ExecJS-based rendering strategy for the open-source React on Rails gem.
    # Wraps the existing RubyEmbeddedJavaScript connection pool.
    #
    # Part of the strategy pattern refactoring (see issue #2905).
    # Currently additive — not yet wired into the main rendering path.
    class ExecJsStrategy
      include ReactOnRails::RenderingStrategy

      def execute(render_request)
        js_code = render_request.to_js
        ReactOnRails::ServerRenderingPool::RubyEmbeddedJavaScript
          .exec_server_render_js(js_code, render_request.render_options)
      end

      def reset
        ReactOnRails::ServerRenderingPool::RubyEmbeddedJavaScript.reset_pool
      end

      def reset_if_bundle_changed
        ReactOnRails::ServerRenderingPool::RubyEmbeddedJavaScript
          .reset_pool_if_server_bundle_was_modified
      end
    end
  end
end

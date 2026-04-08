# frozen_string_literal: true

require_relative "rendering_strategy"

module ReactOnRails
  # Default rendering strategy that delegates through the existing ServerRenderingPool
  # and ServerRenderingJsCode dispatch chain. This preserves backward compatibility with
  # Pro's pool-based integration (ProRendering, NodeRenderingPool) until Pro creates its
  # own NodeRenderingStrategy.
  #
  # Once Pro ships a dedicated strategy, this class can be simplified to delegate
  # directly to RubyEmbeddedJavaScript (removing the pool dispatch).
  class ExecJSRenderingStrategy
    include RenderingStrategy

    # Execute a component render request.
    # Generates JS via ServerRenderingJsCode (which dispatches to Pro if installed),
    # then executes via ServerRenderingPool (which dispatches to Pro if installed).
    # @param render_request [ReactOnRails::RenderRequest]
    # @return [Hash, Stream] Parsed result with "html", "consoleReplayScript", etc.
    def execute(render_request)
      js_code = ServerRenderingJsCode.server_rendering_component_js_code(
        props_string: render_request.props_string,
        rails_context: render_request.rails_context,
        redux_stores: render_request.store_initializations,
        react_component_name: render_request.component_name,
        render_options: render_request.render_options
      )
      execute_js(js_code, render_request.render_options)
    end

    # Execute raw JavaScript code via the rendering pool.
    # Delegates through ServerRenderingPool to preserve Pro dispatch.
    # @param js_code [String] JavaScript expression that returns a JSON string
    # @param render_options [ReactOnRails::ReactComponent::RenderOptions]
    # @return [Hash] Parsed result
    def execute_js(js_code, render_options)
      ServerRenderingPool.server_render_js_with_console_logging(js_code, render_options)
    end

    # Reset the rendering pool.
    def reset
      ServerRenderingPool.reset_pool
    end

    # Check if the server bundle has been modified and reset the pool if needed.
    def reset_if_bundle_changed
      ServerRenderingPool.reset_pool_if_server_bundle_was_modified
    end
  end
end

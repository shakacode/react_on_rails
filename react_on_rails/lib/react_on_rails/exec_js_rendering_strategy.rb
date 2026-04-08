# frozen_string_literal: true

require_relative "rendering_strategy"

module ReactOnRails
  # Core rendering strategy that wraps the existing RubyEmbeddedJavaScript connection pool.
  # Configured as the default at boot time; Pro overrides with NodeRenderingStrategy.
  class ExecJSRenderingStrategy
    include RenderingStrategy

    # Execute a component render request by building JS and evaluating it via ExecJS.
    # @param render_request [ReactOnRails::RenderRequest]
    # @return [Hash] Parsed result with "html", "consoleReplayScript", "hasErrors"
    def execute(render_request)
      js_code = render_request.to_js
      execute_js(js_code, render_request.render_options)
    end

    # Execute raw JavaScript code directly via the ExecJS pool.
    # @param js_code [String] JavaScript expression that returns a JSON string
    # @param render_options [ReactOnRails::ReactComponent::RenderOptions]
    # @return [Hash] Parsed result
    def execute_js(js_code, render_options)
      ServerRenderingPool::RubyEmbeddedJavaScript.exec_server_render_js(js_code, render_options)
    end

    # Reset the ExecJS connection pool.
    def reset
      ServerRenderingPool::RubyEmbeddedJavaScript.reset_pool
    end

    # Check if the server bundle has been modified and reset the pool if needed.
    def reset_if_bundle_changed
      ServerRenderingPool::RubyEmbeddedJavaScript.reset_pool_if_server_bundle_was_modified
    end
  end
end

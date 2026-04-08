# frozen_string_literal: true

module ReactOnRails
  # Strategy interface for server-side rendering. Concrete implementations are configured
  # once at boot time, replacing the runtime react_on_rails_pro? dispatch.
  #
  # Core ships ExecJSRenderingStrategy; Pro overrides with NodeRenderingStrategy.
  #
  # @example Boot-time registration (engine initializers)
  #   # react_on_rails/engine.rb
  #   ReactOnRails.rendering_strategy ||= ReactOnRails::ExecJSRenderingStrategy.new
  #
  #   # react_on_rails_pro/engine.rb (runs after core)
  #   ReactOnRails.rendering_strategy = ReactOnRailsPro::NodeRenderingStrategy.new
  module RenderingStrategy
    # Execute a component render request.
    # @param render_request [ReactOnRails::RenderRequest]
    # @return [Hash, Stream] Parsed result with "html", "consoleReplayScript", etc.
    def execute(render_request)
      raise NotImplementedError, "#{self.class}#execute must be implemented"
    end

    # Execute raw JavaScript code directly (for server_render_js helper).
    # @param js_code [String] JavaScript expression that returns a JSON string
    # @param render_options [ReactOnRails::ReactComponent::RenderOptions]
    # @return [Hash] Parsed result
    def execute_js(js_code, render_options)
      raise NotImplementedError, "#{self.class}#execute_js must be implemented"
    end

    # Reset the rendering pool/context.
    def reset
      raise NotImplementedError, "#{self.class}#reset must be implemented"
    end

    # Check if the server bundle has been modified and reset if needed.
    def reset_if_bundle_changed
      raise NotImplementedError, "#{self.class}#reset_if_bundle_changed must be implemented"
    end
  end
end

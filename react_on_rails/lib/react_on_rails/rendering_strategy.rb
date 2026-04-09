# frozen_string_literal: true

require_relative "rendering_strategy/exec_js_strategy"

module ReactOnRails
  # Strategy interface for server-side rendering. Concrete strategies implement
  # the rendering pipeline (JS execution, caching, streaming) for a specific
  # runtime (ExecJS, Node renderer, etc.).
  #
  # Configured once at boot time via engine initializers, replacing runtime
  # `react_on_rails_pro?` checks.
  #
  # Part of the strategy pattern refactoring (see issue #2905).
  # Currently additive — not yet wired into the main rendering path.
  module RenderingStrategy
    # Execute a server render.
    # @param render_request [RenderRequest] The render request to execute
    # @return [Hash, Stream] Result hash with "html", "consoleReplayScript", "hasErrors" keys,
    #   or a stream for streaming renders.
    # :nocov:
    def execute(render_request)
      raise NotImplementedError, "#{self.class}#execute must be implemented"
    end
    # :nocov:

    # Reset the rendering pool (e.g., after configuration changes).
    # :nocov:
    def reset
      raise NotImplementedError, "#{self.class}#reset must be implemented"
    end
    # :nocov:

    # Check if the server bundle has changed and reset the pool if so.
    # Used in development mode to pick up bundle changes without restarting.
    # :nocov:
    def reset_if_bundle_changed
      raise NotImplementedError, "#{self.class}#reset_if_bundle_changed must be implemented"
    end
    # :nocov:
  end
end

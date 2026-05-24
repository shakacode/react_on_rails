# frozen_string_literal: true

module ReactOnRails
  module NodeRendererProcfile
    DEFAULT_COMMANDS = {
      "Procfile.dev" =>
        "node-renderer: RENDERER_LOG_LEVEL=debug RENDERER_PORT=${RENDERER_PORT:-3800} " \
        "node renderer/node-renderer.js",
      "Procfile.dev-static-assets" =>
        "node-renderer: RENDERER_LOG_LEVEL=debug RENDERER_PORT=${RENDERER_PORT:-3800} " \
        "node renderer/node-renderer.js",
      "Procfile.dev-prod-assets" =>
        "node-renderer: RAILS_ENV=${RAILS_ENV:-development} " \
        "RENDERER_LOG_LEVEL=${RENDERER_LOG_LEVEL:-info} RENDERER_PORT=${RENDERER_PORT:-3800} " \
        "node renderer/node-renderer.js"
    }.freeze

    PROCESS_WITH_RENDERER_PORT_REGEX = %r{
      ^[ \t]*[^:\s]+:
      (?=[^\n]*\bRENDERER_PORT\b)
      (?=[^\n]*(?:\bnode\s+\.?/?(?:renderer|client)/node-renderer\.js\b|\bpnpm\s+run\s+node-renderer\b))
    }x

    def self.command_for(procfile)
      DEFAULT_COMMANDS.fetch(procfile, DEFAULT_COMMANDS.fetch("Procfile.dev"))
    end
  end
end

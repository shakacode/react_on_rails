# frozen_string_literal: true

module ReactOnRails
  module NodeRendererProcfile
    DEV_RENDERER_COMMAND = "node-renderer: RENDERER_LOG_LEVEL=debug RENDERER_PORT=${RENDERER_PORT:-3800} " \
                           "node renderer/node-renderer.js"

    DEFAULT_COMMANDS = {
      # HMR dev and static-asset dev use the same renderer config.
      "Procfile.dev" => DEV_RENDERER_COMMAND,
      "Procfile.dev-static-assets" => DEV_RENDERER_COMMAND,
      "Procfile.dev-prod-assets" =>
        "node-renderer: RAILS_ENV=${RAILS_ENV:-development} " \
        "RENDERER_LOG_LEVEL=${RENDERER_LOG_LEVEL:-info} RENDERER_PORT=${RENDERER_PORT:-3800} " \
        "node renderer/node-renderer.js"
    }.freeze

    PROCESS_WITH_RENDERER_PORT_REGEX = %r{
      ^[ \t]*[^:\s]+:
      (?=[^\n]*\bRENDERER_PORT\b)
      (?=[^\n]*(?:\bnode\s+\.?/?(?:renderer|client)/node-renderer\.js\b|
                 \b(?:pnpm|npm)\s+run\s+node-renderer\b|
                 \byarn\s+(?:run\s+)?node-renderer\b))
    }x

    def self.command_for(procfile)
      # Unknown launchers default to the standard dev command so doctor can still show a useful manual fix.
      DEFAULT_COMMANDS.fetch(procfile) { DEFAULT_COMMANDS.fetch("Procfile.dev") }
    end
  end
end

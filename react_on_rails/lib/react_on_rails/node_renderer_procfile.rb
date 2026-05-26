# frozen_string_literal: true

module ReactOnRails
  module NodeRendererProcfile
    DEV_RENDERER_COMMAND = "node-renderer: RENDERER_LOG_LEVEL=${RENDERER_LOG_LEVEL:-debug} " \
                           "RENDERER_PORT=${RENDERER_PORT:-3800} node renderer/node-renderer.js"

    DEFAULT_COMMANDS = {
      # HMR dev and static-asset dev use the same renderer config.
      "Procfile.dev" => DEV_RENDERER_COMMAND,
      "Procfile.dev-static-assets" => DEV_RENDERER_COMMAND,
      "Procfile.dev-prod-assets" =>
        "node-renderer: RAILS_ENV=${RAILS_ENV:-development} " \
        "RENDERER_LOG_LEVEL=${RENDERER_LOG_LEVEL:-info} RENDERER_PORT=${RENDERER_PORT:-3800} " \
        "node renderer/node-renderer.js"
    }.freeze

    # Matches a Procfile process line that both (a) sets RENDERER_PORT via env
    # var AND (b) starts a recognized Node Renderer command. Hard-coded ports
    # intentionally do not match — doctor always nudges users toward the
    # RENDERER_PORT env-var idiom the generator writes (overridable,
    # self-documenting). The recognized-command branch mirrors
    # NODE_RENDERER_PROCESS_REGEX in pro_setup.rb so the doctor accepts the same
    # set of invocations the generator does (pnpm/npm/yarn with optional `run`).
    PROCESS_WITH_RENDERER_PORT_REGEX = %r{
      ^[ \t]*[^:\s]+:
      (?=[^\n]*\bRENDERER_PORT\b)
      (?=[^\n]*(?:\bnode\s+\.?/?(?:renderer|client)/node-renderer\.js\b|
                 \b(?:pnpm|npm|yarn)\s+(?:run\s+)?node-renderer\b))
    }x

    NEW_RENDERER_SCRIPT_PATH = "renderer/node-renderer.js"
    LEGACY_RENDERER_SCRIPT_PATH = "client/node-renderer.js"

    def self.command_for(procfile, renderer_script: NEW_RENDERER_SCRIPT_PATH)
      # Unknown launchers default to the standard dev command so doctor can still show a useful manual fix.
      base = DEFAULT_COMMANDS.fetch(procfile) { DEFAULT_COMMANDS.fetch("Procfile.dev") }
      return base if renderer_script == NEW_RENDERER_SCRIPT_PATH

      base.sub(NEW_RENDERER_SCRIPT_PATH, renderer_script)
    end
  end
end

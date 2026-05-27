# frozen_string_literal: true

require "erb"
require "yaml"

module ReactOnRails
  module Dev
    module ServerMode
      DEFAULT_SHAKAPACKER_CONFIG_PATH = "config/shakapacker.yml"

      MODE_TEXT = {
        hmr: {
          command_label: "(none) / hmr",
          command_description: "Start development server with HMR (default)",
          procfile_description: "HMR development with webpack-dev-server",
          procfile_dev_label: "HMR Procfile.dev",
          launcher_description: "HMR development (bin/dev default)",
          mode_heading: "🔥 HMR Development mode (default)",
          next_step_label: "HMR",
          workflow_suffix: "for HMR",
          shared_output_warning: "Do not combine shared output path with bin/dev (HMR)",
          refresh_guidance: "Ensure you're running HMR mode: bin/dev (not bin/dev static)",
          refresh_note: "Note: React Refresh only works in HMR mode, not static mode"
        },
        live_reload: {
          command_label: "(none)",
          command_description: "Start development server with live reload (default)",
          procfile_description: "Live reload development with webpack-dev-server",
          procfile_dev_label: "Live reload Procfile.dev",
          launcher_description: "Live reload development (bin/dev default)",
          mode_heading: "🔁 Live reload development mode (default)",
          next_step_label: "live reload",
          workflow_suffix: "for live reload",
          shared_output_warning: "Do not combine shared output path with bin/dev (live reload)",
          refresh_guidance: "HMR is disabled in config/shakapacker.yml; enable dev_server.hmr for React Refresh",
          refresh_note: "With live reload enabled, changes refresh the page instead of preserving component state"
        },
        development_server: {
          command_label: "(none)",
          command_description: "Start development server (default)",
          procfile_description: "Development server with webpack-dev-server",
          procfile_dev_label: "Development server Procfile.dev",
          launcher_description: "Development server (bin/dev default)",
          mode_heading: "🚀 Development server mode (default)",
          next_step_label: "the development server",
          workflow_suffix: "for the development server",
          shared_output_warning: "Do not combine shared output path with bin/dev (development server)",
          refresh_guidance: "Check config/shakapacker.yml has dev_server.hmr: true for React Refresh",
          refresh_note: "React Refresh requires HMR; other dev-server modes may reload the page"
        }
      }.freeze

      MODE_DETAILS = {
        hmr: [
          "Hot Module Replacement (HMR) enabled",
          "React on Rails pack generation (via precompile hook or bin/dev)",
          "Webpack dev server for fast recompilation",
          "Source maps for debugging",
          "May have Flash of Unstyled Content (FOUC)",
          "Fast recompilation"
        ],
        live_reload: [
          "Full-page live reload enabled",
          "React on Rails pack generation (via precompile hook or bin/dev)",
          "Webpack dev server for automatic recompilation",
          "Source maps for debugging",
          "Browser refreshes after changes"
        ],
        development_server: [
          "Webpack dev server enabled",
          "React on Rails pack generation (via precompile hook or bin/dev)",
          "Source maps for debugging",
          "Development server watches for changes"
        ]
      }.freeze

      class << self
        # The fallback preserves legacy HMR wording when no Shakapacker config can be read.
        def detect(config_path = shakapacker_config_path, fallback: :hmr)
          detect_from_config(config_path) || normalize_mode(fallback)
        end

        # This is intentionally narrower than detect: missing, empty, or unparseable config falls back to :hmr for
        # legacy bin/dev help text, but only an explicit HMR config should trigger HMR-specific doctor warnings.
        def hmr_enabled?(config_path = shakapacker_config_path)
          detect_from_config(config_path) == :hmr
        end

        def text(mode, key)
          mode_text = MODE_TEXT.fetch(normalize_mode(mode))
          mode_text.fetch(key) do
            valid_keys = mode_text.keys.join(", ")
            raise ArgumentError, "Unknown ServerMode text key #{key.inspect}. Valid keys: #{valid_keys}"
          end
        end

        def details(mode)
          MODE_DETAILS.fetch(normalize_mode(mode))
        end

        private

        def shakapacker_config_path
          ENV["SHAKAPACKER_CONFIG"] || DEFAULT_SHAKAPACKER_CONFIG_PATH
        end

        def detect_from_config(config_path)
          config = parse_config(config_path)
          return nil unless config.is_a?(Hash)

          dev_server = dev_server_config(config)
          return :live_reload unless dev_server

          detect_from_dev_server_config(dev_server)
        end

        def parse_config(config_path)
          return nil unless File.exist?(config_path)

          # ERB uses the default top-level binding so config files can reference ENV and top-level
          # constants — this mirrors how Shakapacker itself evaluates shakapacker.yml.
          # Symbol values are permitted to match adjacent Shakapacker config parsers.
          YAML.safe_load(ERB.new(File.read(config_path)).result, aliases: true, permitted_classes: [Symbol])
        rescue SyntaxError, StandardError => e
          warn(
            "[ReactOnRails] Could not parse #{config_path} for dev-server mode detection: #{e.message}"
          )
          nil
        end

        def dev_server_config(config)
          # YAML anchors already apply environment-level defaults before this point.
          # Match Shakapacker by reading the resolved development section instead of deep-merging nested
          # dev_server hashes, because a development dev_server block replaces the default one.
          dev_server_section(config["development"])
        end

        def dev_server_section(environment_config)
          return {} unless environment_config.is_a?(Hash)

          dev_server = environment_config["dev_server"]
          dev_server.is_a?(Hash) ? dev_server : {}
        end

        def detect_from_dev_server_config(dev_server)
          return :live_reload if dev_server.empty?

          hmr = hmr_config(dev_server["hmr"])
          live_reload = boolean_config(dev_server["live_reload"])

          return :hmr if hmr == true
          return :live_reload if live_reload == true
          return :development_server if live_reload == false

          # For a non-empty dev_server config without hmr: true or live_reload: false, default to live reload.
          # Shakapacker enables live reload by default unless explicitly disabled:
          # https://github.com/shakacode/shakapacker/blob/main/package/webpackDevServerConfig.ts
          # See generators/react_on_rails/templates/base/base/config/shakapacker.yml.tt.
          :live_reload
        end

        def hmr_config(value)
          # Shakapacker's "hmr: only" is webpack-dev-server-only HMR, not a React on Rails custom value.
          return true if value.to_s.strip.casecmp?("only")

          boolean_config(value)
        end

        def boolean_config(value)
          # Accept unquoted YAML booleans and their quoted, case-insensitive equivalents.
          # Other values (integers, arbitrary strings) return nil so callers can apply mode-specific defaults
          # rather than guessing at JS-style truthiness.
          return true if value == true
          return false if value == false

          if value.is_a?(String)
            stripped = value.strip
            return true if stripped.casecmp?("true")
            return false if stripped.casecmp?("false")
          end

          nil
        end

        def normalize_mode(mode)
          return mode if MODE_TEXT.key?(mode)

          valid_modes = MODE_TEXT.keys.join(", ")
          raise ArgumentError, "Unknown ServerMode #{mode.inspect}. Valid modes: #{valid_modes}"
        end
      end
    end
  end
end

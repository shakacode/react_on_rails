# frozen_string_literal: true

require "erb"
require "yaml"

module ReactOnRails
  module Dev
    module ServerMode
      DEFAULT_SHAKAPACKER_CONFIG_PATH = "config/shakapacker.yml"

      MODE_TEXT = {
        hmr: {
          command_description: "Start development server with HMR (default)",
          procfile_description: "HMR development with webpack-dev-server",
          launcher_description: "HMR development (bin/dev default)",
          mode_heading: "🔥 HMR Development mode (default)",
          next_step_label: "HMR",
          workflow_suffix: "for HMR",
          shared_output_warning: "Do not combine shared output path with bin/dev (HMR)",
          refresh_guidance: "Ensure you're running HMR mode: bin/dev (not bin/dev static)",
          refresh_note: "Note: React Refresh only works in HMR mode, not static mode",
          details: [
            "Hot Module Replacement (HMR) enabled",
            "React on Rails pack generation (via precompile hook or bin/dev)",
            "Webpack dev server for fast recompilation",
            "Source maps for debugging",
            "May have Flash of Unstyled Content (FOUC)",
            "Fast recompilation"
          ]
        },
        live_reload: {
          command_description: "Start development server with live reload (default)",
          procfile_description: "Live reload development with webpack-dev-server",
          launcher_description: "Live reload development (bin/dev default)",
          mode_heading: "🔁 Live reload development mode (default)",
          next_step_label: "live reload",
          workflow_suffix: "for live reload",
          shared_output_warning: "Do not combine shared output path with bin/dev (live reload)",
          refresh_guidance: "HMR is disabled in config/shakapacker.yml; enable dev_server.hmr for React Refresh",
          refresh_note: "With live reload enabled, changes refresh the page instead of preserving component state",
          details: [
            "Full-page live reload enabled",
            "React on Rails pack generation (via precompile hook or bin/dev)",
            "Webpack dev server for automatic recompilation",
            "Source maps for debugging",
            "Browser refreshes after changes"
          ]
        },
        development_server: {
          command_description: "Start development server (default)",
          procfile_description: "Development server with webpack-dev-server",
          launcher_description: "Development server (bin/dev default)",
          mode_heading: "🚀 Development server mode (default)",
          next_step_label: "the development server",
          workflow_suffix: "for the development server",
          shared_output_warning: "Do not combine shared output path with bin/dev (development server)",
          refresh_guidance: "Check config/shakapacker.yml has dev_server.hmr: true for React Refresh",
          refresh_note: "React Refresh requires HMR; other dev-server modes may reload the page",
          details: [
            "Webpack dev server enabled",
            "React on Rails pack generation (via precompile hook or bin/dev)",
            "Source maps for debugging",
            "Development server watches for changes"
          ]
        }
      }.freeze

      class << self
        def detect(config_path = shakapacker_config_path, fallback: :hmr)
          detect_from_config(config_path) || normalize_mode(fallback)
        end

        def hmr_enabled?(config_path = shakapacker_config_path)
          detect(config_path) == :hmr
        end

        def text(mode, key)
          MODE_TEXT.fetch(normalize_mode(mode)).fetch(key) do
            valid_keys = MODE_TEXT.fetch(:hmr).keys.join(", ")
            raise ArgumentError, "Unknown ServerMode text key #{key.inspect}. Valid keys: #{valid_keys}"
          end
        end

        private

        def shakapacker_config_path
          ENV["SHAKAPACKER_CONFIG"] || DEFAULT_SHAKAPACKER_CONFIG_PATH
        end

        def detect_from_config(config_path)
          config = parse_config(config_path)
          return nil unless config.is_a?(Hash)

          detect_from_dev_server_config(dev_server_config(config))
        end

        def parse_config(config_path)
          return nil unless File.exist?(config_path)

          YAML.safe_load(ERB.new(File.read(config_path)).result, permitted_classes: [Symbol], aliases: true)
        rescue Psych::SyntaxError, SyntaxError, Errno::EACCES, Errno::ENOENT => e
          warn(
            "[ReactOnRails] Could not parse #{config_path} for dev-server mode detection: #{e.message}"
          )
          nil
        end

        def dev_server_config(config)
          default_config = config["default"] || {}
          development_config = config["development"] || {}
          default_dev_server = default_config["dev_server"].is_a?(Hash) ? default_config["dev_server"] : {}
          development_dev_server = development_config["dev_server"].is_a?(Hash) ? development_config["dev_server"] : {}

          default_dev_server.merge(development_dev_server)
        end

        def detect_from_dev_server_config(dev_server)
          return nil if dev_server.empty?

          hmr = boolean_config(dev_server["hmr"])
          live_reload = boolean_config(dev_server["live_reload"])

          return :hmr if hmr == true
          return :live_reload if live_reload == true
          return :development_server if hmr == false && live_reload.nil?
          return :development_server if hmr == false

          nil
        end

        def boolean_config(value)
          return true if value == true
          return false if value == false

          normalized = value.to_s.strip.downcase
          return true if normalized == "true"
          return false if normalized == "false"

          nil
        end

        def normalize_mode(mode)
          MODE_TEXT.key?(mode) ? mode : :development_server
        end
      end
    end
  end
end

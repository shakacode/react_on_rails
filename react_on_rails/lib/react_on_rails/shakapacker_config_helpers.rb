# frozen_string_literal: true

require "erb"
require "yaml"

module ReactOnRails
  # Shared helpers for reading config/shakapacker.yml and deriving the active
  # assets bundler (webpack vs rspack), its display labels, and the development
  # dev-server reload mode. Extracted so the diagnostics/CLI entry points
  # (Doctor, SystemChecker, and Dev::ServerManager) parse the file the same way
  # and present consistent bundler wording.
  #
  # Doctor and SystemChecker `include` this module so the helpers become private
  # instance methods. Dev::ServerManager `extend`s it because its commands live
  # on `class << self`; extend preserves the private visibility, so the helpers
  # become private singleton methods there. The helpers call each other plus
  # standard-library/Rails globals (ENV, File, Dir, YAML, ERB, Rails) and module
  # constants — none of which resolve through `self` — so they behave
  # identically whether included or extended.
  module ShakapackerConfigHelpers
    DEFAULT_SHAKAPACKER_CONFIG_PATH = "config/shakapacker.yml"
    SHAKAPACKER_ASSETS_BUNDLER_ENV = "SHAKAPACKER_ASSETS_BUNDLER"
    SUPPORTED_ASSETS_BUNDLERS = %w[webpack rspack].freeze

    private

    # Reads and parses config/shakapacker.yml. Symbol values are permitted so a
    # `key: :value` entry parses instead of raising, matching how
    # ReactOnRails::Dev::ServerMode loads the same file; ScriptError is rescued
    # alongside StandardError because ERB/YAML can raise SyntaxError (a
    # ScriptError, not a StandardError). Returns nil on any failure or when the
    # document is not a mapping.
    def parsed_shakapacker_config
      config_path = shakapacker_config_path
      return nil unless File.exist?(config_path)

      parsed = YAML.safe_load(ERB.new(File.read(config_path)).result, aliases: true, permitted_classes: [Symbol])
      parsed.is_a?(Hash) ? parsed : nil
    rescue StandardError, ScriptError
      nil
    end

    # Resolves SHAKAPACKER_CONFIG the same way ReactOnRails::Engine does, so CLI
    # callers see the same config file as Rails boot even when invoked from a
    # directory other than the Rails root. Falls back to Dir.pwd when Rails
    # isn't loaded (bin/dev does not require Rails directly).
    def shakapacker_config_path
      env_config_path = ENV.fetch("SHAKAPACKER_CONFIG", nil)
      base = shakapacker_config_base_dir
      return File.expand_path(DEFAULT_SHAKAPACKER_CONFIG_PATH, base) if env_config_path.to_s.empty?

      File.expand_path(env_config_path, base)
    end

    def shakapacker_config_base_dir
      return Rails.root.to_s if defined?(Rails) && Rails.respond_to?(:root) && Rails.root

      Dir.pwd
    end

    def configured_assets_bundler
      config = parsed_shakapacker_config
      return nil unless config.is_a?(Hash)

      # No rescue here on purpose: parsed_shakapacker_config already returns nil
      # on any config-file failure, and the section lookups below only do Hash
      # access plus string normalization. A raise past this point is a
      # programming error (e.g. a missing require for SUPPORTED_ASSETS_BUNDLERS)
      # and should surface loudly rather than silently degrade to "webpack".
      rails_env = ENV["RAILS_ENV"] || ENV["RACK_ENV"] || "development"
      bundler_from_shakapacker_section(config, rails_env) || bundler_from_shakapacker_section(config, "default")
    end

    def bundler_from_shakapacker_section(config, section_name)
      section = config[section_name] || config[section_name.to_sym]
      return nil unless section.is_a?(Hash)

      normalize_assets_bundler(section["assets_bundler"] || section[:assets_bundler])
    end

    def normalize_assets_bundler(value)
      normalized = value.to_s.strip.downcase
      SUPPORTED_ASSETS_BUNDLERS.include?(normalized) ? normalized : nil
    end

    def env_assets_bundler
      normalize_assets_bundler(ENV.fetch(SHAKAPACKER_ASSETS_BUNDLER_ENV, nil))
    end

    def active_assets_bundler
      env_assets_bundler || configured_assets_bundler || "webpack"
    end

    def assets_bundler_label
      active_assets_bundler.capitalize
    end

    def dev_server_label
      active_assets_bundler == "webpack" ? "webpack-dev-server" : "#{assets_bundler_label} dev server"
    end

    def development_reload_mode_label
      development_hmr_enabled? ? "HMR" : "Live reload"
    end

    def development_hmr_enabled?
      dev_server = development_dev_server_config
      return hmr_config_value?(dev_server["hmr"]) if dev_server.key?("hmr")

      return false if truthy_config_value?(dev_server["live_reload"])

      # Default to HMR when neither hmr nor live_reload is configured, preserving historical behavior.
      true
    end

    def hmr_config_value?(value)
      value.to_s.strip.casecmp?("only") || truthy_config_value?(value)
    end

    def development_dev_server_config
      config = parsed_shakapacker_config
      return {} unless config.is_a?(Hash)

      development_config = shakapacker_section(config, "default").merge(shakapacker_section(config, "development"))
      dev_server_config_for(development_config)
    end

    def shakapacker_section(config, section_name)
      section = config[section_name] || config[section_name.to_sym]
      section.is_a?(Hash) ? section : {}
    end

    def dev_server_config_for(section)
      dev_server = section["dev_server"] || section[:dev_server]
      return {} unless dev_server.is_a?(Hash)

      dev_server.transform_keys(&:to_s)
    end

    def truthy_config_value?(value)
      value == true || value.to_s == "true"
    end
  end
end

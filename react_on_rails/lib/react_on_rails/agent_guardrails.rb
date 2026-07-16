# frozen_string_literal: true

require "json"
require "fileutils"

module ReactOnRails
  # Installs (and idempotently updates) the RSC "agent guardrail" assets into a host app:
  # a Claude Code skill and an advisory PostToolUse hook that steer AI agents away from the
  # React Server Components API footguns (unauthenticated payload route, trusting props, exposing
  # the Node renderer, leaking secrets). Invoked by `rake react_on_rails:install_rsc_agent_guardrails`
  # and by the RSC generator.
  module AgentGuardrails
    Error = Class.new(StandardError)

    TEMPLATES_DIR = File.expand_path("agent_guardrails/templates", __dir__)

    # source template (under TEMPLATES_DIR) => destination path relative to the app root
    FILES = {
      "rsc_app_safety_skill.md" => ".claude/skills/rsc-app-safety/SKILL.md",
      "rsc_app_safety_check.rb" => ".claude/hooks/rsc-app-safety-check.rb"
    }.freeze

    HOOK_COMMAND = "ruby"
    HOOK_ARGS = ["${CLAUDE_PROJECT_DIR}/.claude/hooks/rsc-app-safety-check.rb"].freeze
    LEGACY_HOOK_COMMAND = "${CLAUDE_PROJECT_DIR}/.claude/hooks/rsc-app-safety-check.sh"
    LEGACY_HOOK_REL = ".claude/hooks/rsc-app-safety-check.sh"
    HOOK_REL = ".claude/hooks/rsc-app-safety-check.rb"
    HOOK_MATCHER = "Edit|Write"
    SETTINGS_REL = ".claude/settings.json"

    # Copies the guardrail files and registers the advisory hook. Idempotent: re-running only
    # writes what changed. Returns an array of human-readable action strings.
    def self.install(destination_root, skip_existing: false)
      new_installer(destination_root, skip_existing:).install
    end

    def self.new_installer(destination_root, skip_existing: false)
      Installer.new(destination_root, skip_existing:)
    end

    # Encapsulates a single install run against one app root.
    class Installer
      def initialize(destination_root, skip_existing: false)
        @destination_root = File.expand_path(destination_root.to_s)
        @skip_existing = skip_existing
      end

      def install
        validate_settings_before_copy
        actions = FILES.map { |source, dest_rel| copy_file(source, dest_rel) }
        actions << register_hook
        actions << remove_legacy_hook
        actions.compact
      end

      private

      attr_reader :destination_root, :skip_existing

      def validate_settings_before_copy
        settings_path = File.join(destination_root, SETTINGS_REL)
        return if skip_existing && File.exist?(settings_path)

        read_settings(settings_path)
      end

      def copy_file(source, dest_rel)
        source_path = File.join(TEMPLATES_DIR, source)
        dest_path = File.join(destination_root, dest_rel)
        existed = File.exist?(dest_path)
        return "skipped    #{dest_rel} (already exists)" if skip_existing && existed

        new_content = File.read(source_path)
        unchanged = existed && File.read(dest_path) == new_content

        unless unchanged
          FileUtils.mkdir_p(File.dirname(dest_path))
          File.write(dest_path, new_content)
        end
        File.chmod(0o755, dest_path) if dest_rel == HOOK_REL

        return "unchanged  #{dest_rel}" if unchanged

        existed ? "updated    #{dest_rel}" : "created    #{dest_rel}"
      end

      def register_hook
        settings_path = File.join(destination_root, SETTINGS_REL)
        return "skipped    #{SETTINGS_REL} (already exists)" if skip_existing && File.exist?(settings_path)

        settings = read_settings(settings_path)
        return "unchanged  #{SETTINGS_REL} (hook already registered)" if hook_registered?(settings)

        add_hook(settings)
        FileUtils.mkdir_p(File.dirname(settings_path))
        existed = File.exist?(settings_path)
        File.write(settings_path, "#{JSON.pretty_generate(settings)}\n")
        existed ? "updated    #{SETTINGS_REL} (registered hook)" : "created    #{SETTINGS_REL} (registered hook)"
      end

      def remove_legacy_hook
        legacy_path = File.join(destination_root, LEGACY_HOOK_REL)
        return unless File.exist?(legacy_path)
        return "skipped    #{LEGACY_HOOK_REL} (already exists)" if skip_existing

        FileUtils.rm_f(legacy_path)
        "removed    #{LEGACY_HOOK_REL} (replaced by #{HOOK_REL})"
      end

      def read_settings(path)
        return {} unless File.exist?(path)

        content = File.read(path).strip
        return {} if content.empty?

        settings = JSON.parse(content)
        raise Error, invalid_settings_message unless valid_settings_shape?(settings)

        settings
      rescue JSON::ParserError
        raise Error, invalid_settings_message
      end

      def valid_settings_shape?(settings)
        return false unless settings.is_a?(Hash)

        hooks = settings["hooks"]
        return true if hooks.nil?
        return false unless hooks.is_a?(Hash)

        valid_post_tool_use?(hooks["PostToolUse"])
      end

      def valid_post_tool_use?(entries)
        return true if entries.nil?

        entries.is_a?(Array) && entries.all? { |entry| valid_hook_group?(entry) }
      end

      def valid_hook_group?(entry)
        return false unless entry.is_a?(Hash)

        hooks = entry["hooks"]
        hooks.nil? || (hooks.is_a?(Array) && hooks.all?(Hash))
      end

      def invalid_settings_message
        "#{SETTINGS_REL} is not valid JSON for Claude settings, so it was left untouched. Add this " \
          "PostToolUse (#{HOOK_MATCHER}) command hook manually: #{HOOK_COMMAND} #{HOOK_ARGS.join(' ')}"
      end

      def hook_registered?(settings)
        entries = Array(settings.dig("hooks", "PostToolUse"))
        managed_hooks = entries.flat_map { |entry| Array(entry["hooks"]) }.select { |hook| managed_hook?(hook) }
        return false unless managed_hooks.one? && registered_hook?(managed_hooks.first)

        entries.any? do |entry|
          entry["matcher"] == HOOK_MATCHER && Array(entry["hooks"]).include?(managed_hooks.first)
        end
      end

      def add_hook(settings)
        hooks = (settings["hooks"] ||= {})
        post_tool_use = (hooks["PostToolUse"] ||= [])
        post_tool_use.each do |candidate|
          Array(candidate["hooks"]).reject! { |hook| managed_hook?(hook) }
        end
        entry = post_tool_use.find { |candidate| candidate["matcher"] == HOOK_MATCHER }
        unless entry
          entry = { "matcher" => HOOK_MATCHER, "hooks" => [] }
          post_tool_use << entry
        end
        (entry["hooks"] ||= []) << { "type" => "command", "command" => HOOK_COMMAND, "args" => HOOK_ARGS }
      end

      def registered_hook?(hook)
        hook["type"] == "command" && hook["command"] == HOOK_COMMAND && hook["args"] == HOOK_ARGS
      end

      def managed_hook?(hook)
        registered_hook?(hook) || hook["command"] == LEGACY_HOOK_COMMAND
      end
    end
  end
end

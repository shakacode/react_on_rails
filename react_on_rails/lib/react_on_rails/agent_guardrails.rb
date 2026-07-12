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
      "rsc_app_safety_check.sh" => ".claude/hooks/rsc-app-safety-check.sh"
    }.freeze

    HOOK_COMMAND = "${CLAUDE_PROJECT_DIR}/.claude/hooks/rsc-app-safety-check.sh"
    HOOK_MATCHER = "Edit|Write"
    SETTINGS_REL = ".claude/settings.json"

    # Copies the guardrail files and registers the advisory hook. Idempotent: re-running only
    # writes what changed. Returns an array of human-readable action strings.
    def self.install(destination_root)
      new_installer(destination_root).install
    end

    def self.new_installer(destination_root)
      Installer.new(destination_root)
    end

    # Encapsulates a single install run against one app root.
    class Installer
      def initialize(destination_root)
        @destination_root = File.expand_path(destination_root.to_s)
      end

      def install
        actions = FILES.map { |source, dest_rel| copy_file(source, dest_rel) }
        actions << register_hook
        actions
      end

      private

      attr_reader :destination_root

      def copy_file(source, dest_rel)
        source_path = File.join(TEMPLATES_DIR, source)
        dest_path = File.join(destination_root, dest_rel)
        new_content = File.read(source_path)

        return "unchanged  #{dest_rel}" if File.exist?(dest_path) && File.read(dest_path) == new_content

        existed = File.exist?(dest_path)
        FileUtils.mkdir_p(File.dirname(dest_path))
        File.write(dest_path, new_content)
        File.chmod(0o755, dest_path) if dest_path.end_with?(".sh")
        existed ? "updated    #{dest_rel}" : "created    #{dest_rel}"
      end

      def register_hook
        settings_path = File.join(destination_root, SETTINGS_REL)
        settings = read_settings(settings_path)
        return "unchanged  #{SETTINGS_REL} (hook already registered)" if hook_registered?(settings)

        add_hook(settings)
        FileUtils.mkdir_p(File.dirname(settings_path))
        existed = File.exist?(settings_path)
        File.write(settings_path, "#{JSON.pretty_generate(settings)}\n")
        existed ? "updated    #{SETTINGS_REL} (registered hook)" : "created    #{SETTINGS_REL} (registered hook)"
      end

      def read_settings(path)
        return {} unless File.exist?(path)

        content = File.read(path).strip
        return {} if content.empty?

        JSON.parse(content)
      rescue JSON::ParserError
        raise Error, "#{SETTINGS_REL} is not valid JSON, so it was left untouched. Add this " \
                     "PostToolUse (#{HOOK_MATCHER}) command hook manually: #{HOOK_COMMAND}"
      end

      def hook_registered?(settings)
        Array(settings.dig("hooks", "PostToolUse")).any? do |entry|
          Array(entry["hooks"]).any? { |hook| hook["command"].to_s.include?("rsc-app-safety-check.sh") }
        end
      end

      def add_hook(settings)
        hooks = (settings["hooks"] ||= {})
        post_tool_use = (hooks["PostToolUse"] ||= [])
        entry = post_tool_use.find { |candidate| candidate["matcher"] == HOOK_MATCHER }
        unless entry
          entry = { "matcher" => HOOK_MATCHER, "hooks" => [] }
          post_tool_use << entry
        end
        (entry["hooks"] ||= []) << { "type" => "command", "command" => HOOK_COMMAND }
      end
    end
  end
end

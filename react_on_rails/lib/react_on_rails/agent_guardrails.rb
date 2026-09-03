# frozen_string_literal: true

require "json"
require "fileutils"
require "tempfile"

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

    # Where guardrails get installed when no explicit destination is given. Prefers the Rails
    # application root so the task installs into the app's `.claude/` even when rake is invoked
    # from a subdirectory; falls back to the working directory outside a Rails app.
    def self.default_destination_root(explicit = nil)
      explicit = explicit.to_s
      return explicit unless explicit.empty?

      rails_root = defined?(Rails) && Rails.respond_to?(:root) ? Rails.root : nil
      rails_root ? rails_root.to_s : Dir.pwd
    end

    module FileOwnership
      module_function

      def preserve(existing_stat, path)
        return unless existing_stat

        File.chown(existing_stat.uid, existing_stat.gid, path)
      rescue Errno::EPERM, Errno::EINVAL
        nil
      end
    end
    private_constant :FileOwnership

    module FileWriter
      module_function

      def ensure_existing_writable!(path)
        return unless File.exist?(path)
        return if File.writable?(path)

        raise Errno::EACCES, path
      end

      # Prefer rename over truncate-and-write so interrupted writes cannot leave a partial destination.
      # Copied guardrails may retain the old in-place behavior when directory permissions block replacement.
      def write(path, content, new_file_mode: 0o644, allow_in_place_fallback: false, ensure_executable: false)
        existing_stat = File.stat(path) if File.exist?(path)
        temp = Tempfile.create([".#{File.basename(path)}", ".tmp"], File.dirname(path))
        begin
          temp.write(content)
          temp.flush
          temp.fsync
          temp.close
          FileOwnership.preserve(existing_stat, temp.path)
          File.chmod(existing_stat ? existing_stat.mode & 0o7777 : new_file_mode, temp.path)
          File.rename(temp.path, path)
          :atomic
        rescue StandardError
          FileUtils.rm_f(temp.path)
          raise
        end
      rescue Errno::EACCES, Errno::EPERM
        raise unless existing_stat && allow_in_place_fallback

        prepare_in_place(path, ensure_executable)
        File.write(path, content)
        :in_place
      end

      def finish_copy(path, ensure_executable:, strategy:)
        return unless ensure_executable
        return if strategy == :in_place

        File.chmod(0o755, path)
      end

      def prepare_in_place(path, ensure_executable)
        return unless ensure_executable
        return if File.executable?(path)

        File.chmod(0o755, path)
      end
      private_class_method :prepare_in_place
    end
    private_constant :FileWriter

    # Encapsulates a single install run against one app root.
    class Installer
      def initialize(destination_root, skip_existing: false)
        @destination_root = File.expand_path(destination_root.to_s)
        @skip_existing = skip_existing
      end

      def install
        copy_write_paths = validate_copy_paths_before_copy
        settings_write_path = validate_settings_before_copy
        actions = FILES.map { |source, dest_rel| copy_file(source, dest_rel, copy_write_paths.fetch(dest_rel)) }
        actions.push(register_hook(settings_write_path), remove_legacy_hook).compact
      end

      private

      attr_reader :destination_root, :skip_existing

      def validate_settings_before_copy
        settings_path = File.join(destination_root, SETTINGS_REL)
        if skip_existing && path_entry_exists?(settings_path)
          raise Error, "#{SETTINGS_REL} is a dangling symlink, so it cannot be skipped safely" unless
            File.exist?(settings_path)

          return settings_path
        end

        read_settings(settings_path)
        write_path_for(settings_path)
      end

      def validate_copy_paths_before_copy
        FILES.values.to_h do |dest_rel|
          dest_path = File.join(destination_root, dest_rel)
          if skip_existing && path_entry_exists?(dest_path)
            # A missing skipped hook would still be registered; a missing skill remains intentionally skipped.
            raise Error, "#{HOOK_REL} is a dangling symlink, so its missing target cannot be skipped safely" if
              dest_rel == HOOK_REL && !File.exist?(dest_path)

            next [dest_rel, dest_path]
          end
          [dest_rel, write_path_for(dest_path)]
        end
      end

      def copy_file(source, dest_rel, write_path)
        source_path = File.join(TEMPLATES_DIR, source)
        dest_path = File.join(destination_root, dest_rel)
        hook = dest_rel == HOOK_REL
        existed = path_entry_exists?(dest_path)
        return "skipped    #{dest_rel} (already exists)" if skip_existing && existed

        new_content = File.read(source_path)
        unchanged = File.exist?(dest_path) && File.read(dest_path) == new_content
        write_strategy = nil

        unless unchanged
          # File.write previously required an existing guardrail target to be writable even when its parent
          # directory could replace it. Preserve that protection before selecting the atomic replacement path.
          FileWriter.ensure_existing_writable!(write_path)

          FileUtils.mkdir_p(File.dirname(write_path))
          write_strategy = FileWriter.write(
            write_path,
            new_content,
            new_file_mode: 0o666 & ~File.umask,
            allow_in_place_fallback: true,
            ensure_executable: hook
          )
        end
        FileWriter.finish_copy(write_path, ensure_executable: hook, strategy: write_strategy)

        return "unchanged  #{dest_rel}" if unchanged

        existed ? "updated    #{dest_rel}" : "created    #{dest_rel}"
      end

      def register_hook(settings_write_path)
        settings_path = File.join(destination_root, SETTINGS_REL)
        return "skipped    #{SETTINGS_REL} (already exists)" if skip_existing && path_entry_exists?(settings_path)

        settings = read_settings(settings_path)
        return "unchanged  #{SETTINGS_REL} (hook already registered)" if hook_registered?(settings)

        add_hook(settings)
        FileUtils.mkdir_p(File.dirname(settings_path))
        existed = path_entry_exists?(settings_path)
        FileWriter.write(settings_write_path, "#{JSON.pretty_generate(settings)}\n")
        existed ? "updated    #{SETTINGS_REL} (registered hook)" : "created    #{SETTINGS_REL} (registered hook)"
      end

      def path_entry_exists?(path)
        File.exist?(path) || File.symlink?(path)
      end

      def write_path_for(path)
        return path unless File.symlink?(path)

        File.realdirpath(path)
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

      # Settings are validated before anything is copied, so reaching here means NOTHING was
      # installed — including #{HOOK_REL}. The recovery therefore has to be "fix the settings and
      # re-run", not "register the hook manually": the hook script does not exist yet, so pointing
      # Claude at it would leave the advisory guardrail silently disabled.
      def invalid_settings_message
        "#{SETTINGS_REL} is not valid JSON for Claude settings, so it was left untouched and no " \
          "guardrail files were installed (#{HOOK_REL} does not exist yet). Fix or remove " \
          "#{SETTINGS_REL}, then re-run `rake react_on_rails:install_rsc_agent_guardrails` to " \
          "install the hook and register it as a PostToolUse (#{HOOK_MATCHER}) command hook."
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
        remove_managed_hooks(post_tool_use)
        entry = post_tool_use.find { |candidate| candidate["matcher"] == HOOK_MATCHER }
        unless entry
          entry = { "matcher" => HOOK_MATCHER, "hooks" => [] }
          post_tool_use << entry
        end
        (entry["hooks"] ||= []) << { "type" => "command", "command" => HOOK_COMMAND, "args" => HOOK_ARGS }
      end

      def remove_managed_hooks(post_tool_use)
        post_tool_use.reject! do |candidate|
          candidate_hooks = candidate["hooks"]
          next false unless candidate_hooks

          removed_hooks = candidate_hooks.reject! { |hook| managed_hook?(hook) }
          removed_hooks && candidate_hooks.empty?
        end
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

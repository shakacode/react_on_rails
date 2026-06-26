# frozen_string_literal: true

require "English"
require "fileutils"
require "net/http"
require "open3"
require "optparse"
require "rainbow"
require "erb"
require "rbconfig"
require "socket"
require "time"
require "uri"
require "yaml"
require_relative "../packer_utils"
require_relative "../shakapacker_config_helpers"
require_relative "../system_checker"
require_relative "database_checker"
require_relative "server_mode"
require_relative "service_checker"

module ReactOnRails
  module Dev
    class ServerManager
      # Commands live on `class << self`, so extend (rather than include) the
      # shared shakapacker-config helpers to expose them as singleton methods.
      extend ReactOnRails::ShakapackerConfigHelpers

      HELP_FLAGS = ["-h", "--help"].freeze
      TEST_WATCH_MODES = %w[auto full client-only].freeze
      CLEAN_SHAKAPACKER_ENVIRONMENTS = %w[development test production].freeze
      OPEN_BROWSER_WAIT_TIMEOUT = 60
      OPEN_BROWSER_POLL_INTERVAL = 0.5
      DOCS_BASE_URL = "https://reactonrails.com/docs"
      DEV_SERVER_AND_TESTING_DOCS_URL = "#{DOCS_BASE_URL}/building-features/dev-server-and-testing/".freeze
      TESTING_CONFIGURATION_DOCS_URL = "#{DOCS_BASE_URL}/building-features/testing-configuration/".freeze

      class << self
        def start(mode = :development, procfile = nil, verbose: false, route: nil, rails_env: nil,
                  skip_database_check: false, open_browser: false, open_browser_once: false)
          case mode
          when :production_like
            run_production_like(_verbose: verbose, route:, rails_env:,
                                skip_database_check:,
                                open_browser:,
                                open_browser_once:)
          when :static
            procfile ||= "Procfile.dev-static-assets"
            run_static_development(procfile, verbose:, route:,
                                             skip_database_check:,
                                             open_browser:,
                                             open_browser_once:)
          when :development, :hmr
            procfile ||= "Procfile.dev"
            run_development(procfile, verbose:, route:,
                                      skip_database_check:,
                                      open_browser:,
                                      open_browser_once:)
          else
            raise ArgumentError, "Unknown mode: #{mode}"
          end
        end

        def kill_processes
          puts "🔪 Killing all development processes..."
          puts ""

          # Run every cleanup step unconditionally so a successful first step
          # (e.g. pattern-based kill) doesn't leave stale port-bound processes
          # or socket/pid files behind. `.any?` still gives us the
          # "anything actually got killed?" signal for the summary message.
          killed_any = [
            kill_running_processes,
            kill_port_processes(killable_ports),
            cleanup_socket_files
          ].any?

          print_kill_summary(killed_any)
        end

        def clean_generated_assets_and_caches
          puts "🧹 Cleaning generated bundles and caches..."
          puts ""
          kill_processes
          puts ""
          print_shakapacker_config_status
          puts ""

          clean_finished_without_warnings = remove_clean_targets(clean_targets)

          puts ""
          if clean_finished_without_warnings
            puts "✅ Generated bundles and caches cleaned"
          else
            puts "⚠️  Cleanup completed with warnings"
          end
        end

        # Fallback port list for the port-scan kill path. Uses the base-port
        # derived ports when REACT_ON_RAILS_BASE_PORT / CONDUCTOR_PORT is set,
        # so `bin/dev kill` in a worktree on ports 5000/5001/5002 targets the
        # right ports instead of the 3000/3001 default. Falls back to
        # [3000, 3001] when no base port is configured, plus the renderer port
        # when Pro renderer support is active. Uses PortSelector's pure
        # #base_port_hash so no "Base port detected" banner prints during a kill.
        #
        # In base-port mode we include base[:renderer] whenever the Pro gem is
        # loaded, even if the current shell has no renderer env vars set. The
        # user has explicitly claimed this port range, and `bin/dev kill` is
        # usually invoked from a fresh shell where RENDERER_PORT / *_URL aren't
        # carried over from the dev session — so requiring env-var presence
        # would let a stale renderer survive. Pattern-based killing
        # (development_processes / node.*react[-_]on[-_]rails) does NOT catch
        # the Pro renderer because it runs as `node renderer/node-renderer.js`
        # with no "react_on_rails" substring in the command line. Port-based
        # killing is the only reliable path. The default-port branch keeps the
        # tighter renderer_env_signal? guard via configured_renderer_port_for_kill
        # because 3800 is a shared default that could belong to an unrelated process.
        def killable_ports
          base = PortSelector.base_port_hash
          return default_killable_ports unless base

          ports = [base[:rails], base[:webpack]]
          if pro_renderer_active?
            # When the Pro gem is loaded but no renderer env var is set, the
            # user may not realize base+2 is being scanned. Surface it so an
            # unrelated process killed on that port isn't a silent surprise.
            unless renderer_env_signal?
              puts "   ℹ️  Including renderer port #{base[:renderer]} (base+2): " \
                   "react_on_rails_pro is loaded but no renderer env var is set."
            end
            ports << base[:renderer]
          end
          ports
        end

        def default_killable_ports
          ports = [3000, 3001]
          if pro_renderer_active?
            renderer_port = configured_renderer_port_for_kill
            ports << renderer_port if renderer_port
          end
          ports
        end

        def configured_renderer_port_for_kill
          raw_port = ENV.fetch("RENDERER_PORT", nil)
          return raw_port.strip.to_i if valid_port_string?(raw_port)

          local_url_port = local_renderer_url_port_for_kill
          return local_url_port if local_url_port
          return nil if remote_renderer_url_configured?

          # Only fall back to the default renderer port when the user has set
          # at least one renderer env var. Without that signal (Pro gem loaded
          # but no renderer ever started), `bin/dev kill` would otherwise
          # target an unrelated process bound to 3800 in OSS+Pro-gem apps.
          renderer_env_signal? ? 3800 : nil
        end

        def local_renderer_url_port_for_kill
          %w[REACT_RENDERER_URL RENDERER_URL].each do |var|
            url = ENV.fetch(var, nil)
            next if url.nil? || url.strip.empty?

            parsed = URI.parse(url)
            next unless localhost_hostname?(parsed.hostname)
            next unless url.match?(URL_WITH_EXPLICIT_PORT_RE)

            return parsed.port
          rescue URI::InvalidURIError
            next
          end

          nil
        end

        def remote_renderer_url_configured?
          %w[REACT_RENDERER_URL RENDERER_URL].any? do |var|
            url = ENV.fetch(var, nil)
            !url.nil? && !url.strip.empty? && !localhost_renderer_url?(url)
          end
        end

        def development_processes
          {
            "rails" => "Rails server",
            "node.*react[-_]on[-_]rails" => "React on Rails Node processes",
            "overmind" => "Overmind process manager",
            "foreman" => "Foreman process manager",
            "ruby.*puma" => "Puma server",
            "webpack-dev-server" => "Webpack dev server",
            "bin/shakapacker-dev-server" => "Shakapacker dev server"
          }
        end

        def kill_running_processes
          killed_any = false

          development_processes.each do |pattern, description|
            pids = find_process_pids(pattern)
            next unless pids.any?

            puts "   ☠️  Killing #{description} (PIDs: #{pids.join(', ')})"
            terminate_processes(pids)
            killed_any = true
          end

          killed_any
        end

        def find_process_pids(pattern)
          stdout, _status = Open3.capture2("pgrep", "-f", pattern, err: File::NULL)
          stdout.split("\n").map(&:to_i).reject { |pid| pid == Process.pid }
        rescue Errno::ENOENT
          # pgrep command not found
          []
        end

        def terminate_processes(pids)
          pids.each do |pid|
            Process.kill("TERM", pid)
          rescue Errno::ESRCH, ArgumentError, RangeError
            # Process already stopped, or invalid signal/PID - silently skip
            nil
          rescue Errno::EPERM
            # Permission denied - warn the user
            puts "   ⚠️  Process #{pid} - permission denied (process owned by another user)"
            nil
          end
        end

        def kill_port_processes(ports)
          killed_any = false

          ports.each do |port|
            pids = find_port_pids(port)
            next unless pids.any?

            puts "   ☠️  Killing process on port #{port} (PIDs: #{pids.join(', ')})"
            terminate_processes(pids)
            killed_any = true
          end

          killed_any
        end

        def find_port_pids(port)
          stdout, _status = Open3.capture2("lsof", "-ti", ":#{port}", err: File::NULL)
          stdout.split("\n").map(&:to_i).reject { |pid| pid == Process.pid }
        rescue StandardError
          # lsof command not found or other error (permission denied, etc.)
          []
        end

        def cleanup_socket_files
          # Mirrors FileManager#cleanup_overmind_sockets so renamed/copied
          # variants like overmind-4100.sock are removed during `bin/dev kill`,
          # not just at startup.
          overmind_sockets = Dir.glob("tmp/sockets/overmind*.sock")
          files = [".overmind.sock", *overmind_sockets, "tmp/pids/server.pid"].uniq
          killed_any = false

          files.each do |file|
            next unless File.exist?(file)

            puts "   🧹 Removing #{file}"
            File.delete(file)
            killed_any = true
          rescue StandardError
            nil
          end

          killed_any
        end

        def print_kill_summary(killed_any)
          if killed_any
            puts ""
            puts "✅ All processes terminated and sockets cleaned"
            puts "💡 You can now run 'bin/dev' for a clean start"
          else
            puts "   ℹ️  No development processes found running"
          end
        end

        def show_help
          default_mode = default_dev_server_mode

          puts help_usage
          puts ""
          puts help_commands(default_mode)
          puts ""
          puts help_options
          puts ""
          puts help_customization(default_mode)
          puts ""
          puts help_mode_details(default_mode)
          puts ""
          puts help_troubleshooting(default_mode)
        end

        # Flags that take a value as the next argument (not using = syntax)
        FLAGS_WITH_VALUES = %w[--route --rails-env --test-watch-mode].freeze

        # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
        def run_from_command_line(args = ARGV)
          # Get the command early to check for help/kill before running hooks
          # We need to do this before OptionParser processes flags like -h/--help
          # Skip arguments that are values for flags (e.g., "hello_world" after "--route")
          command = extract_command_from_args(args)

          # Check if help flags are present in args (before OptionParser processes them)
          help_requested = args.any? { |arg| HELP_FLAGS.include?(arg) }

          options = parse_cli_options(args)

          # Run precompile hook once before starting any mode (except kill/clean/help)
          # Then set environment variable to prevent duplicate execution in spawned processes.
          # Note: We always set SHAKAPACKER_SKIP_PRECOMPILE_HOOK=true (even when no hook is configured)
          # to provide a consistent signal that bin/dev is managing the precompile lifecycle.
          # This allows custom scripts to detect bin/dev's presence and adjust behavior accordingly.
          unless %w[kill clean help].include?(command) || help_requested
            run_precompile_hook_if_present
            ENV["SHAKAPACKER_SKIP_PRECOMPILE_HOOK"] = "true"
          end

          # Main execution
          case command
          when "production-assets", "prod"
            start(:production_like, nil, verbose: options[:verbose], route: options[:route],
                                         rails_env: options[:rails_env],
                                         skip_database_check: options[:skip_database_check],
                                         open_browser: options[:open_browser],
                                         open_browser_once: options[:open_browser_once])
          when "static"
            start(:static, "Procfile.dev-static-assets", verbose: options[:verbose], route: options[:route],
                                                         skip_database_check: options[:skip_database_check],
                                                         open_browser: options[:open_browser],
                                                         open_browser_once: options[:open_browser_once])
          when "kill"
            kill_processes
          when "clean"
            clean_generated_assets_and_caches
          when "help"
            show_help
          when "test-watch"
            run_test_watch(test_watch_mode: options[:test_watch_mode])
          when "hmr", nil
            start(:development, "Procfile.dev", verbose: options[:verbose], route: options[:route],
                                                skip_database_check: options[:skip_database_check],
                                                open_browser: options[:open_browser],
                                                open_browser_once: options[:open_browser_once])
          else
            puts "Unknown argument: #{command}"
            puts "Run 'dev help' for usage information"
            exit 1
          end
        end
        # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity

        private

        def clean_targets
          deduplicate_clean_targets(
            shakapacker_clean_targets +
              common_clean_targets +
              renderer_bundle_cache_targets
          )
        end

        def shakapacker_clean_targets
          shakapacker_sections_for_cleanup.flat_map do |environment, section|
            public_output_path = shakapacker_public_output_path(section)
            private_output_path = section["private_output_path"].to_s.strip
            cache_path = section["cache_path"].to_s.strip
            targets = [
              clean_target(public_output_path, "Shakapacker #{environment} public output")
            ]
            unless private_output_path.empty?
              targets << clean_target(private_output_path, "Shakapacker #{environment} private output")
            end
            targets << clean_target(cache_path, "Shakapacker #{environment} cache") unless cache_path.empty?
            targets
          end
        end

        def shakapacker_sections_for_cleanup
          config = parsed_shakapacker_config
          return [] unless config

          default_section = stringify_config_keys(shakapacker_section(config, "default"))
          environment_names = ["default"] | (config.keys.map(&:to_s) - ["default"]) | CLEAN_SHAKAPACKER_ENVIRONMENTS
          environment_names.map do |environment|
            section = default_section.merge(stringify_config_keys(shakapacker_section(config, environment)))
            [environment, section]
          end
        end

        def shakapacker_public_output_path(section)
          public_root_path = section["public_root_path"].to_s.strip
          public_root_path = "public" if public_root_path.empty?

          public_output_path = section["public_output_path"].to_s.strip
          public_output_path = "packs" if public_output_path.empty?

          return public_output_path if File.absolute_path?(public_output_path)

          File.join(public_root_path, public_output_path)
        end

        def common_clean_targets
          [
            clean_target("public/assets", "Rails compiled assets"),
            clean_target("tmp/cache", "Rails/Shakapacker cache"),
            clean_target("node_modules/.cache", "JavaScript bundler cache"),
            clean_target(".node-renderer-bundles", "node renderer bundle cache")
          ]
        end

        def renderer_bundle_cache_targets
          targets = []
          renderer_cache_path = ENV.fetch("RENDERER_SERVER_BUNDLE_CACHE_PATH", "").strip
          unless renderer_cache_path.empty?
            targets << clean_target(renderer_cache_path, "configured node renderer bundle cache")
          end

          Dir.glob(File.join(app_root_path, "tmp/node-renderer-bundles-test-*")).each do |path|
            targets << clean_target(path, "test node renderer bundle cache")
          end

          targets
        end

        def clean_target(path, label)
          { path: File.expand_path(path, app_root_path), label: }
        end

        def deduplicate_clean_targets(targets)
          targets.each_with_object({}) do |target, deduplicated|
            deduplicated[target[:path]] ||= target
          end.values
        end

        def remove_clean_targets(targets)
          all_targets_clean = true

          targets.each do |target|
            path = target.fetch(:path)
            label = target.fetch(:label)
            display_path = display_clean_path(path)

            unless safe_clean_path?(path)
              all_targets_clean = false
              puts "⚠️  Skipping unsafe cleanup path: #{display_path} (#{label})"
              next
            end

            unless File.exist?(path) || File.symlink?(path)
              puts "   • #{display_path} (not present)"
              next
            end

            FileUtils.rm_rf(path)
            if File.exist?(path) || File.symlink?(path)
              all_targets_clean = false
              puts "⚠️  Partially removed #{display_path} - some files could not be deleted (#{label})"
            else
              puts "   ✓ Removed #{display_path} (#{label})"
            end
          end

          all_targets_clean
        end

        def print_shakapacker_config_status
          config_path = shakapacker_config_path
          if parsed_shakapacker_config
            puts "📖 Reading Shakapacker config: #{display_clean_path(config_path)}"
          elsif File.exist?(config_path)
            puts "📖 Could not parse Shakapacker config: #{display_clean_path(config_path)}"
            puts "   • Skipping configured Shakapacker output/cache paths"
          else
            puts "📖 Shakapacker config not found: #{display_clean_path(config_path)}"
            puts "   • Skipping configured Shakapacker output/cache paths"
          end
        end

        def safe_clean_path?(path)
          return false unless path_inside_app_root?(path)
          return false if broad_clean_path?(path)
          return false unless real_clean_path_inside_app_root?(path)

          true
        end

        def path_inside_app_root?(path)
          path.start_with?("#{app_root_path}/")
        end

        def real_clean_path_inside_app_root?(path)
          return true unless File.exist?(path) || File.symlink?(path)
          return broken_symlink_target_inside_app_root?(path) if File.symlink?(path) && !File.exist?(path)

          real_path = File.realpath(path)
          path_inside_real_app_root?(real_path)
        rescue Errno::ENOENT, Errno::ELOOP, Errno::ENOTDIR, Errno::EINVAL, Errno::EACCES
          false
        end

        def broken_symlink_target_inside_app_root?(path)
          parent_real_path = File.realpath(File.dirname(path))
          return false unless parent_real_path == real_app_root_path || path_inside_real_app_root?(parent_real_path)

          link_target = File.readlink(path)
          resolved_path = File.expand_path(link_target, File.dirname(path))
          path_inside_app_root?(resolved_path) || path_inside_real_app_root?(resolved_path)
        rescue Errno::ENOENT, Errno::ELOOP, Errno::ENOTDIR, Errno::EINVAL, Errno::EACCES
          false
        end

        def path_inside_real_app_root?(path)
          path.start_with?("#{real_app_root_path}/")
        end

        def real_app_root_path
          root_path = app_root_path
          return @real_app_root_path if @real_app_root_path_for == root_path

          @real_app_root_path_for = root_path
          @real_app_root_path = File.realpath(root_path)
        rescue Errno::ENOENT, Errno::ELOOP, Errno::ENOTDIR, Errno::EINVAL, Errno::EACCES
          @real_app_root_path = root_path
        end

        def broad_clean_path?(path)
          [
            app_root_path,
            File.join(app_root_path, "public"),
            File.join(app_root_path, "tmp"),
            File.join(app_root_path, "node_modules")
          ].include?(path)
        end

        def display_clean_path(path)
          root_prefix = "#{app_root_path}/"
          return path.delete_prefix(root_prefix) if path.start_with?(root_prefix)

          path
        end

        def app_root_path
          base_dir = shakapacker_config_base_dir
          return @app_root_path if @app_root_path_base_dir == base_dir

          @app_root_path_base_dir = base_dir
          @app_root_path = File.expand_path(base_dir)
        end

        def stringify_config_keys(hash)
          hash.transform_keys(&:to_s)
        end

        # Extract the command from args, skipping flag values
        # For example, in ["--route", "hello_world"], "hello_world" is a flag value, not a command
        # But in ["static", "--route", "hello_world"], "static" is the command
        def extract_command_from_args(args)
          skip_next = false
          args.each do |arg|
            if skip_next
              skip_next = false
              next
            end

            # Check if this flag takes a value as the next argument
            if FLAGS_WITH_VALUES.include?(arg)
              skip_next = true
              next
            end

            # Skip any flag (starts with - or --)
            next if arg.start_with?("-")

            # Found a non-flag, non-value argument - this is the command
            return arg
          end
          nil
        end

        def run_precompile_hook_if_present
          require "open3"
          require "shellwords"

          hook_value = PackerUtils.shakapacker_precompile_hook_value
          return unless hook_value

          # Warn if Shakapacker version doesn't support SHAKAPACKER_SKIP_PRECOMPILE_HOOK
          warn_if_shakapacker_version_too_old

          puts Rainbow("🔧 Running Shakapacker precompile hook...").cyan
          puts Rainbow("   Command: #{hook_value}").cyan
          puts ""

          # Capture stdout and stderr for better error reporting
          # Use Shellwords.split for safer command execution (prevents shell metacharacter interpretation)
          command_args = Shellwords.split(hook_value.to_s)
          stdout, stderr, status = Open3.capture3(*command_args)

          if status.success?
            puts Rainbow("✅ Precompile hook completed successfully").green
            puts ""
          else
            handle_precompile_hook_failure(hook_value, stdout, stderr)
          end
        end

        def run_test_watch(test_watch_mode: "auto")
          resolved_mode = resolve_test_watch_mode(test_watch_mode)
          return unless resolved_mode

          env = { "RAILS_ENV" => "test" }
          if resolved_mode == "client-only"
            env["CLIENT_BUNDLE_ONLY"] = "true"
            puts Rainbow("🧪 Starting test watch (client-only mode)...").cyan
            puts Rainbow("   Reusing server bundle from existing watcher if available.").cyan
          else
            puts Rainbow("🧪 Starting test watch (full mode)...").cyan
            puts Rainbow("   Building both client and server test bundles.").cyan
          end
          puts Rainbow("   Command: #{env.map { |k, v| "#{k}=#{v}" }.join(' ')} bin/shakapacker --watch").cyan
          puts ""

          exec(env, "bin/shakapacker", "--watch")
        end

        def resolve_test_watch_mode(mode)
          normalized_mode = mode.to_s.strip
          normalized_mode = "auto" if normalized_mode.empty?

          unless TEST_WATCH_MODES.include?(normalized_mode)
            puts "❌ Invalid --test-watch-mode '#{mode}'. Use one of: #{TEST_WATCH_MODES.join(', ')}"
            exit 1
          end

          return normalized_mode unless normalized_mode == "auto"

          shakapacker_watch_process_running? ? "client-only" : "full"
        end

        def shakapacker_watch_process_running?
          # Detect existing shakapacker watcher processes (from either bin/dev or bin/dev static).
          # If one is already running, client-only test watch avoids duplicate server-bundle rebuilds.
          # Also detect legacy =yes convention during transition
          server_only_watchers = find_process_pids("SERVER_BUNDLE_ONLY=true bin/shakapacker --watch")
          server_only_watchers |= find_process_pids("SERVER_BUNDLE_ONLY=yes bin/shakapacker --watch")
          if server_only_watchers.any?
            return true if shared_private_output_paths?

            puts Rainbow(
              "   Existing server-bundle-only watcher found, " \
              "but test/development private outputs differ; using full mode."
            ).yellow
            return false
          end

          full_watchers = find_process_pids("bin/shakapacker --watch")
          if full_watchers.any? && shakapacker_dev_server_running?
            return true if shared_private_output_paths?

            puts Rainbow(
              "   Existing dev-server/watcher pair found, " \
              "but test/development private outputs differ; using full mode."
            ).yellow
            return false
          end

          return false if full_watchers.empty?
          return true if shared_private_output_paths?

          puts Rainbow("   Existing shakapacker watcher found, but bundle sharing is unclear; using full mode.").yellow

          false
        end

        def shakapacker_dev_server_running?
          find_process_pids("bin/shakapacker-dev-server").any?
        end

        def shared_private_output_paths?
          shakapacker_config = parsed_shakapacker_config
          return false unless shakapacker_config.is_a?(Hash)

          default_config = shakapacker_config["default"] || {}
          development_config = default_config.merge(shakapacker_config["development"] || {})
          test_config = default_config.merge(shakapacker_config["test"] || {})
          development_private = development_config["private_output_path"]
          test_private = test_config["private_output_path"]

          return false unless development_private && test_private

          development_private == test_private
        end

        def default_procfile_description(default_mode)
          bundler_aware_dev_server_text(ServerMode.text(default_mode, :procfile_description))
        end

        def static_procfile_description
          if active_assets_bundler == "webpack"
            "Static development with webpack --watch"
          else
            "Static development with #{active_assets_bundler} watch"
          end
        end

        def bundler_aware_dev_server_text(text)
          return text if active_assets_bundler == "webpack"

          text
            .gsub("webpack-dev-server", dev_server_label)
            .gsub(
              "Webpack dev server for automatic recompilation",
              "#{assets_bundler_label} dev server for fast recompilation"
            )
            .gsub("Webpack dev server", "#{assets_bundler_label} dev server")
            .gsub("webpack dev server", "#{active_assets_bundler} dev server")
        end

        def react_refresh_bundler_plugin_description
          if active_assets_bundler == "webpack"
            "webpack plugin"
          else
            "#{active_assets_bundler} React Refresh plugin"
          end
        end

        def react_refresh_bundler_config_hint
          case active_assets_bundler
          when "webpack"
            "config/webpack/development.js: ReactRefreshWebpackPlugin (enabled when WEBPACK_SERVE=true)"
          when "rspack"
            "config/rspack/development.js: @rspack/plugin-react-refresh / ReactRefreshRspackPlugin " \
            "(enabled for the dev server)"
          else
            "Check your bundler's React Refresh plugin documentation"
          end
        end

        def compilation_failed_label
          if active_assets_bundler == "webpack"
            "Webpack compilation failed"
          else
            "#{assets_bundler_label} compilation failed"
          end
        end

        # rubocop:disable Metrics/AbcSize
        def handle_precompile_hook_failure(hook_value, stdout, stderr)
          puts ""
          puts Rainbow("❌ Precompile hook failed!").red.bold
          puts Rainbow("   Command: #{hook_value}").red
          puts ""

          if stdout && !stdout.strip.empty?
            puts Rainbow("   Output:").yellow
            stdout.strip.split("\n").each { |line| puts Rainbow("   #{line}").yellow }
            puts ""
          end

          if stderr && !stderr.strip.empty?
            puts Rainbow("   Error:").red
            stderr.strip.split("\n").each { |line| puts Rainbow("   #{line}").red }
            puts ""
          end

          puts Rainbow("💡 Fix the hook command in config/shakapacker.yml or remove it to continue").yellow
          exit 1
        end
        # rubocop:enable Metrics/AbcSize

        # rubocop:disable Metrics/AbcSize
        def warn_if_shakapacker_version_too_old
          # Only warn for Shakapacker versions in the range 9.0.0 to 9.3.x
          # Versions below 9.0.0 don't use the precompile_hook feature
          # Versions 9.4.0+ support SHAKAPACKER_SKIP_PRECOMPILE_HOOK environment variable natively
          has_precompile_hook_support = PackerUtils.shakapacker_version_requirement_met?("9.0.0")
          has_skip_env_var_support = PackerUtils.shakapacker_version_requirement_met?("9.4.0")

          return unless has_precompile_hook_support
          return if has_skip_env_var_support

          hook_value = PackerUtils.shakapacker_precompile_hook_value
          return unless hook_value

          # Case 1: Script-based hook WITH self-guard -> fully protected, no warning needed
          return if PackerUtils.hook_script_has_self_guard?(hook_value)

          # Case 2: Script-based hook WITHOUT self-guard -> actionable warning
          script_path = PackerUtils.resolve_hook_script_path(hook_value)
          if script_path
            puts ""
            puts Rainbow("⚠️  Warning: #{script_path} is missing the self-guard line").yellow.bold
            puts ""
            puts Rainbow("   Without it, the precompile hook may run multiple times in HMR mode").yellow
            puts Rainbow("   (once by bin/dev, and again by each webpack process).").yellow
            puts ""
            puts Rainbow("   Add this line near the top of your hook script:").cyan
            puts Rainbow('   exit 0 if ENV["SHAKAPACKER_SKIP_PRECOMPILE_HOOK"] == "true"').cyan.bold
            puts ""
            return
          end

          # Case 3: Direct command hook -> suggest upgrade or switch to script-based hook
          puts ""
          puts Rainbow("⚠️  Warning: Shakapacker #{PackerUtils.shakapacker_version} detected").yellow.bold
          puts ""
          puts Rainbow("   The SHAKAPACKER_SKIP_PRECOMPILE_HOOK environment variable is not").yellow
          puts Rainbow("   supported in Shakapacker versions below 9.4.0. This may cause the").yellow
          puts Rainbow("   precompile_hook to run multiple times (once by bin/dev, and again").yellow
          puts Rainbow("   by each webpack process).").yellow
          puts ""
          puts Rainbow("   Recommendations:").cyan
          puts Rainbow("   1. Upgrade to Shakapacker 9.4.0 or later:").cyan
          puts Rainbow("      bundle update shakapacker").cyan.bold
          puts Rainbow("   2. Or switch to a script-based hook with a self-guard.").cyan
          puts Rainbow("      See: https://reactonrails.com/docs/building-features/process-managers").cyan
          puts ""
        end
        # rubocop:enable Metrics/AbcSize

        def help_usage
          Rainbow("📋 Usage: bin/dev [command] [options]").bold
        end

        # rubocop:disable Metrics/AbcSize
        def help_commands(default_mode)
          command_label_text = ServerMode.text(default_mode, :command_label)
          command_label = Rainbow(command_label_text).green.bold
          command_padding = " " * [20 - command_label_text.length, 1].max
          command_description = Rainbow(ServerMode.text(default_mode, :command_description)).white

          <<~COMMANDS
            #{Rainbow('🚀 COMMANDS:').cyan.bold}
              #{command_label}#{command_padding}#{command_description}
                                  #{Rainbow('→ Uses:').yellow} Procfile.dev

              #{Rainbow('static').green.bold}              #{Rainbow('Start development server with static assets (watch mode, no FOUC)').white}
                                  #{Rainbow('→ Uses:').yellow} Procfile.dev-static-assets

              #{Rainbow('production-assets').green.bold}   #{Rainbow('Start with production-optimized assets (no HMR)').white}
              #{Rainbow('prod').green.bold}                #{Rainbow('Alias for production-assets').white}
                                  #{Rainbow('→ Uses:').yellow} Procfile.dev-prod-assets

              #{Rainbow('test-watch').green.bold}          #{Rainbow('Watch and rebuild test assets with smart defaults').white}
                                  #{Rainbow('→ Uses:').yellow} bin/shakapacker --watch (RAILS_ENV=test)

              #{Rainbow('kill').red.bold}                #{Rainbow('Kill all development processes for a clean start').white}
              #{Rainbow('clean').red.bold}               #{Rainbow('Kill dev processes and remove generated bundles/caches').white}
              #{Rainbow('help').blue.bold}                #{Rainbow('Show this help message').white}
          COMMANDS
        end
        # rubocop:enable Metrics/AbcSize

        # rubocop:disable Metrics/AbcSize
        def help_options
          <<~OPTIONS
            #{Rainbow('⚙️  OPTIONS:').cyan.bold}
              #{Rainbow('--route ROUTE').green.bold}        #{Rainbow('Specify route to display in URLs (default: root)').white}
              #{Rainbow('--rails-env ENV').green.bold}      #{Rainbow('Override RAILS_ENV for assets:precompile step only (prod mode only)').white}
              #{Rainbow('--verbose, -v').green.bold}        #{Rainbow('Enable verbose output for pack generation').white}
              #{Rainbow('--skip-database-check').green.bold} #{Rainbow('Skip database connectivity check (saves ~1-2s startup time)').white}
              #{Rainbow('--open-browser').green.bold}       #{Rainbow('Open the app URL in your browser when the server is ready').white}
              #{Rainbow('--open-browser-once').green.bold}  #{Rainbow('Open the app once, then remember that it was already opened').white}
              #{Rainbow('--no-open-browser').green.bold}    #{Rainbow('Disable automatic browser opening for this run').white}
              #{Rainbow('--test-watch-mode MODE').green.bold} #{Rainbow('For test-watch: auto, full, or client-only').white}

            #{Rainbow('📝 EXAMPLES:').cyan.bold}
              #{Rainbow('bin/dev prod').green.bold}                    #{Rainbow('# NODE_ENV=production, RAILS_ENV=development').white}
              #{Rainbow('bin/dev prod --rails-env=production').green.bold}  #{Rainbow('# NODE_ENV=production, RAILS_ENV=production').white}
              #{Rainbow('bin/dev prod --route=dashboard').green.bold}       #{Rainbow('# Custom route in URLs').white}
              #{Rainbow('bin/dev --skip-database-check').green.bold}        #{Rainbow('# Skip DB check for faster startup').white}
              #{Rainbow('bin/dev --open-browser').green.bold}               #{Rainbow('# Open the app after the server comes up').white}
              #{Rainbow('bin/dev --no-open-browser').green.bold}            #{Rainbow('# Override generated auto-open behavior').white}
              #{Rainbow('bin/dev test-watch').green.bold}                    #{Rainbow('# Auto-select full/client-only test watch').white}
              #{Rainbow('bin/dev test-watch --test-watch-mode=full').green.bold} #{Rainbow('# Always build server+client test bundles').white}
          OPTIONS
        end
        # rubocop:enable Metrics/AbcSize

        # rubocop:disable Metrics/AbcSize
        def help_customization(default_mode)
          procfile_description = default_procfile_description(default_mode)
          workflow_suffix = Rainbow(ServerMode.text(default_mode, :workflow_suffix)).white

          <<~CUSTOMIZATION
            #{Rainbow('🔧 CUSTOMIZATION:').cyan.bold}
            Each mode uses a specific Procfile that you can customize for your application:

            #{Rainbow('•').yellow} #{Rainbow('Procfile.dev').green.bold}                 - #{procfile_description}
            #{Rainbow('•').yellow} #{Rainbow('Procfile.dev-static-assets').green.bold}   - #{static_procfile_description}
            #{Rainbow('•').yellow} #{Rainbow('Procfile.dev-prod-assets').green.bold}     - Production-optimized assets (port 3001)

            #{Rainbow('Edit these files to customize the development environment for your needs.').white}

            #{Rainbow('🗄️  DATABASE CHECK:').cyan.bold}
            #{Rainbow('bin/dev checks database connectivity before starting (adds ~1-2s to startup).').white}
            #{Rainbow('Disable this check if you don\'t use a database or want faster startup:').white}

            #{Rainbow('•').yellow} #{Rainbow('CLI flag:').white}     #{Rainbow('bin/dev --skip-database-check').green.bold}
            #{Rainbow('•').yellow} #{Rainbow('Environment:').white}  #{Rainbow('SKIP_DATABASE_CHECK=true bin/dev').green.bold}
            #{Rainbow('•').yellow} #{Rainbow('Config:').white}       #{Rainbow('config.check_database_on_dev_start = false').green.bold} #{Rainbow('(in react_on_rails.rb)').white}

            #{Rainbow('🔍 SERVICE DEPENDENCIES:').cyan.bold}
            #{Rainbow('Configure required external services in').white} #{Rainbow('.dev-services.yml').green.bold}#{Rainbow(':').white}

            #{Rainbow('•').yellow} #{Rainbow('bin/dev').white} #{Rainbow('checks services before starting (optional)').white}
            #{Rainbow('•').yellow} #{Rainbow('Copy from').white} #{Rainbow('.dev-services.yml.example').green.bold} #{Rainbow('to get started').white}
            #{Rainbow('•').yellow} #{Rainbow('Supports Redis, PostgreSQL, Elasticsearch, and custom services').white}
            #{Rainbow('•').yellow} #{Rainbow('Shows helpful errors with start commands if services are missing').white}

            #{Rainbow('🧪 TEST ASSET WORKFLOWS:').cyan.bold}
            #{Rainbow('Recommended default (separate outputs):').white}
            #{Rainbow('•').yellow} #{Rainbow('Keep test public_output_path different from development (for example, packs-test vs packs)').white}
            #{Rainbow('•').yellow} #{Rainbow('Use').white} #{Rainbow('bin/dev').green.bold} #{workflow_suffix}
            #{Rainbow('•').yellow} #{Rainbow('Use').white} #{Rainbow('bin/dev test-watch').green.bold} #{Rainbow('to watch test assets').white}
            #{Rainbow('•').yellow} #{Rainbow('Override mode when needed:').white} #{Rainbow('--test-watch-mode=full').green.bold} #{Rainbow('or').white} #{Rainbow('--test-watch-mode=client-only').green.bold}

            #{Rainbow('Advanced static-only workflow (shared output):').white}
            #{Rainbow('•').yellow} #{Rainbow('Only use shared test/dev output with').white} #{Rainbow('bin/dev static').green.bold}
            #{Rainbow('•').yellow} #{Rainbow(ServerMode.text(default_mode, :shared_output_warning)).white}

            #{Rainbow('Example .dev-services.yml:').white}
            #{Rainbow('  services:').cyan}
            #{Rainbow('    redis:').cyan}
            #{Rainbow('      check_command: "redis-cli ping"').cyan}
            #{Rainbow('      expected_output: "PONG"').cyan}
            #{Rainbow('      start_command: "redis-server"').cyan}
          CUSTOMIZATION
        end
        # rubocop:enable Metrics/AbcSize

        # rubocop:disable Metrics/AbcSize
        def help_mode_details(default_mode)
          # Reflect base-port mode so help text advertises the port `bin/dev`
          # will actually use. Without this, `bin/dev help` in a worktree with
          # REACT_ON_RAILS_BASE_PORT=4000 still claims 3000/3001.
          default_mode_details = default_dev_server_detail_lines(default_mode)
          dev_url  = "http://localhost:#{help_display_port(:dev)}/<route>"
          prod_url = "http://localhost:#{help_display_port(:prod)}/<route>"
          mode_heading = Rainbow(ServerMode.text(default_mode, :mode_heading)).cyan.bold
          procfile_dev = Rainbow("Procfile.dev").green

          <<~MODES
            #{mode_heading} - #{procfile_dev}:
            #{default_mode_details}
            #{Rainbow('•').yellow} #{Rainbow('Access at:').white} #{Rainbow(dev_url).cyan.underline}

            #{Rainbow('📦 Static development mode').cyan.bold} - #{Rainbow('Procfile.dev-static-assets').green}:
            #{Rainbow('•').yellow} #{Rainbow('No HMR (static assets with auto-recompilation)').white}
            #{Rainbow('•').yellow} #{Rainbow('React on Rails pack generation (via precompile hook or bin/dev)').white}
            #{Rainbow('•').yellow} #{Rainbow("#{assets_bundler_label} watch mode for auto-recompilation").white}
            #{Rainbow('•').yellow} #{Rainbow('CSS extracted to separate files (no FOUC)').white}
            #{Rainbow('•').yellow} #{Rainbow('Development environment (faster builds than production)').white}
            #{Rainbow('•').yellow} #{Rainbow('Source maps for debugging').white}
            #{Rainbow('•').yellow} #{Rainbow('Optional advanced testing: share output path with tests only in this mode').white}
            #{Rainbow('•').yellow} #{Rainbow('Access at:').white} #{Rainbow(dev_url).cyan.underline}

            #{Rainbow('🏭 Production-assets mode').cyan.bold} - #{Rainbow('Procfile.dev-prod-assets').green}:
            #{Rainbow('•').yellow} #{Rainbow('React on Rails pack generation (via precompile hook or assets:precompile)').white}
            #{Rainbow('•').yellow} #{Rainbow("Asset precompilation with NODE_ENV=production (#{active_assets_bundler} optimizations)").white}
            #{Rainbow('•').yellow} #{Rainbow('RAILS_ENV=development by default for assets:precompile (avoids credentials)').white}
            #{Rainbow('•').yellow} #{Rainbow('Use --rails-env=production for assets:precompile only (not server processes)').white}
            #{Rainbow('•').yellow} #{Rainbow('Server processes controlled by Procfile.dev-prod-assets environment').white}
            #{Rainbow('•').yellow} #{Rainbow('Optimized, minified bundles with CSS extraction').white}
            #{Rainbow('•').yellow} #{Rainbow('No HMR (static assets)').white}
            #{Rainbow('•').yellow} #{Rainbow('Access at:').white} #{Rainbow(prod_url).cyan.underline}
          MODES
        end
        # rubocop:enable Metrics/AbcSize

        # Returns the Rails port to advertise in `bin/dev help`. In base-port
        # mode every mode uses `base + 0` (apply_base_port_env sets PORT
        # uniformly across HMR/static/prod-assets); otherwise prod-assets
        # defaults to 3001 and HMR/static default to 3000. Uses base_port_hash
        # so help-rendering is silent (no banner) and read-only.
        def help_display_port(mode)
          base = PortSelector.base_port_hash
          return base[:rails] if base

          mode == :prod ? 3001 : 3000
        end

        # Intentionally not memoized: ServerManager methods live on `class << self`, so memoizing
        # would persist across the entire process and leak state between specs that swap
        # shakapacker.yml. `show_help` captures the result in a local before passing it down,
        # so there is only one ServerMode.detect call per help render. Doctor memoizes because
        # it owns instance state on a fresh Doctor instance per invocation.
        def default_dev_server_mode
          ServerMode.detect(shakapacker_config_path)
        end

        def default_dev_server_detail_lines(mode)
          ServerMode.details(mode).map do |detail|
            "#{Rainbow('•').yellow} #{Rainbow(bundler_aware_dev_server_text(detail)).white}"
          end.join("\n")
        end

        def help_react_refresh_troubleshooting(default_mode)
          return help_hmr_react_refresh_troubleshooting if default_mode == :hmr

          troubleshooting = <<~REFRESH
            #{Rainbow('⚛️  React Refresh:').yellow.bold}
            #{Rainbow('React Refresh requires HMR; current default mode is not HMR.').white}
            #{Rainbow('•').yellow} #{Rainbow(ServerMode.text(default_mode, :refresh_guidance)).white}
            #{Rainbow('•').yellow} #{Rainbow(ServerMode.text(default_mode, :refresh_note)).white}
          REFRESH

          # Append the rspack/other-bundler config-hint bullet only when present so it
          # lines up with the bullets above; webpack returns "" and we skip it rather
          # than emitting a trailing blank line.
          hint = rspack_react_refresh_config_hint
          hint.empty? ? troubleshooting : "#{troubleshooting}#{hint}\n"
        end

        def rspack_react_refresh_config_hint
          return "" if active_assets_bundler == "webpack"

          "#{Rainbow('•').yellow} #{Rainbow(react_refresh_bundler_config_hint).white}"
        end

        # Only called when the default dev-server mode is HMR, so the mode is always :hmr here.
        # rubocop:disable Metrics/AbcSize
        def help_hmr_react_refresh_troubleshooting
          plugin_check = "Check that both babel plugin and #{react_refresh_bundler_plugin_description} are configured:"

          # The babel `react-refresh/babel` plugin is gated on WEBPACK_SERVE in the
          # generated babel.config.js for both webpack and rspack apps, so that
          # qualifier intentionally stays bundler-agnostic. The bundler-specific
          # parts are the plugin_check heading (via react_refresh_bundler_plugin_description)
          # and the config-hint line below (react_refresh_bundler_config_hint).
          <<~REFRESH
            #{Rainbow('⚛️  React Refresh Issues:').yellow.bold}
            #{Rainbow('If you see "$RefreshSig$ is not defined" errors:').white}
            #{Rainbow('1.').green} #{Rainbow(plugin_check).white}
               #{Rainbow('•').yellow} #{Rainbow('babel.config.js: \'react-refresh/babel\' plugin (enabled when WEBPACK_SERVE=true)').white}
               #{Rainbow('•').yellow} #{Rainbow(react_refresh_bundler_config_hint).white}
            #{Rainbow('2.').green} #{Rainbow(ServerMode.text(:hmr, :refresh_guidance)).white}
            #{Rainbow('3.').green} #{Rainbow('Try restarting the development server:').white} #{Rainbow('bin/dev kill && bin/dev').green.bold}
            #{Rainbow('4.').green} #{Rainbow(ServerMode.text(:hmr, :refresh_note)).white}
          REFRESH
        end
        # rubocop:enable Metrics/AbcSize

        # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
        def run_production_like(_verbose: false, route: nil, rails_env: nil, skip_database_check: false,
                                open_browser: false, open_browser_once: false)
          procfile = "Procfile.dev-prod-assets"

          # Honor base-port mode (REACT_ON_RAILS_BASE_PORT / CONDUCTOR_PORT)
          # before falling through to the prod-specific 3001 auto-scan, so
          # parallel worktrees running `bin/dev prod` don't silently collide
          # on port 3001. warn_if_legacy_renderer_url_env_used fires here too
          # so the RENDERER_URL rename warning surfaces in prod mode.
          #
          # The `unless apply_base_port_if_active` branch mirrors
          # #configure_ports (the canonical per-mode env-setup) but intentionally
          # differs in two ways: (1) PORT auto-scan starts at 3001 (via
          # procfile_port) rather than 3000, and (2) SHAKAPACKER_DEV_SERVER_PORT
          # is omitted because production-like mode runs static assets, not
          # webpack-dev-server. sync_renderer_port_and_url still runs so Pro
          # users who set RENDERER_PORT get the same auto-derivation and
          # mismatch warnings as `bin/dev` and `bin/dev static`.
          warn_if_legacy_renderer_url_env_used
          unless apply_base_port_if_active
            # Set PORT before foreman starts — foreman injects its own PORT=5000
            # into child processes when ENV["PORT"] is unset, overriding the
            # ${PORT:-3001} fallback in the Procfile. Scan from 3001 (not 3000)
            # so prod-assets doesn't collide with the normal dev server.
            #
            # Also normalize invalid/out-of-range values: ${PORT:-3001} only
            # falls back on empty/unset, so `PORT=abc` or `PORT=99999` would
            # otherwise flow straight through to `rails s -p …` and fail to
            # start.
            existing_port = ENV.fetch("PORT", nil)
            if valid_port_string?(existing_port)
              # Strip whitespace so a value like " 3001 " doesn't leak into ENV
              # unstripped — mirrors overwrite_invalid_port_env's normalization
              # used by configure_ports so all bin/dev modes leave ENV["PORT"]
              # in the same shape for downstream consumers (Procfile expansion,
              # exact ENV string comparisons).
              stripped = existing_port.strip
              ENV["PORT"] = stripped if stripped != existing_port
            else
              unless existing_port.nil? || existing_port.strip.empty?
                warn "WARNING: PORT=#{existing_port.inspect} is not a valid port; using auto-selected port."
              end
              # Clear the bad value first so procfile_port falls back to its default
              # (3001) instead of `"abc".to_i == 0`, which would scan from port 0.
              ENV.delete("PORT")
              # Match configure_ports' clean-exit behavior on exhaustion so
              # `bin/dev prod` surfaces a one-line error instead of a backtrace.
              begin
                ENV["PORT"] = PortSelector.find_available_port(procfile_port(procfile)).to_s
              rescue PortSelector::NoPortAvailable => e
                warn e.message
                exit 1
              end
            end
            sync_renderer_port_and_url
          end

          features = [
            "Precompiling assets with production optimizations",
            "Running Rails server on port #{procfile_port(procfile)}",
            "No HMR (Hot Module Replacement)",
            "CSS extracted to separate files (no FOUC)"
          ]

          # NOTE: Pack generation happens automatically during assets:precompile
          # either via precompile hook or via the configuration.rb adjust_precompile_task

          print_procfile_info(procfile, route:)

          # Check database setup before starting
          exit 1 unless DatabaseChecker.check_database(skip: skip_database_check)

          # Check required services before starting
          exit 1 unless ServiceChecker.check_services

          print_server_info(
            "🏭 Starting production-like development server...",
            features,
            procfile_port(procfile),
            route:
          )

          # Precompile assets with production bundler optimizations (includes pack generation automatically)
          env = { "NODE_ENV" => "production" }

          # Validate and sanitize rails_env to prevent shell injection
          if rails_env
            unless rails_env.match?(/\A[a-z0-9_]+\z/i)
              puts "❌ Invalid rails_env: '#{rails_env}'. Must contain only letters, numbers, and underscores."
              exit 1
            end
            env["RAILS_ENV"] = rails_env
          end

          argv = ["bundle", "exec", "rails", "assets:precompile"]

          puts "🔨 Precompiling assets with production #{active_assets_bundler} optimizations..."
          puts ""

          puts Rainbow("ℹ️  Asset Precompilation Environment:").blue
          puts "   • NODE_ENV=production → #{assets_bundler_label} optimizations (minification, compression)"
          if rails_env
            puts "   • RAILS_ENV=#{rails_env} → Custom Rails environment for assets:precompile only"
            puts "   • Note: RAILS_ENV=production requires credentials, database setup, etc."
            puts "   • Server processes will use environment from Procfile.dev-prod-assets"
          else
            puts "   • RAILS_ENV=development → Simpler Rails setup (no credentials needed)"
            puts "   • Use --rails-env=production for assets:precompile step only"
            puts "   • Server processes will use environment from Procfile.dev-prod-assets"
            puts "   • Gets production #{active_assets_bundler} bundles without production Rails complexity"
          end
          puts ""

          env_display = env.map { |k, v| "#{k}=#{v}" }.join(" ")
          puts "#{Rainbow('💻 Running:').blue} #{env_display} #{argv.join(' ')}"
          puts ""

          # Capture both stdout and stderr
          require "open3"
          stdout, stderr, status = Open3.capture3(env, *argv)

          if status.success?
            puts "✅ Assets precompiled successfully"
            ensure_default_port(procfile)
            schedule_browser_open_if_requested(procfile,
                                               route:,
                                               open_browser:,
                                               open_browser_once:)
            ProcessManager.ensure_procfile(procfile)
            ProcessManager.run_with_process_manager(procfile)
          else
            puts "❌ Asset precompilation failed"
            puts ""

            # Combine and display all output
            all_output = []
            all_output << stdout unless stdout.empty?
            all_output << stderr unless stderr.empty?

            unless all_output.empty?
              puts Rainbow("📋 Full Command Output:").red.bold
              puts Rainbow("─" * 60).red
              all_output.each { |output| puts output }
              puts Rainbow("─" * 60).red
              puts ""
            end

            puts Rainbow("🛠️  To debug this issue:").yellow.bold
            command_display = "#{env_display} #{argv.join(' ')}"
            puts "#{Rainbow('1.').cyan} #{Rainbow('Run the command separately to see detailed output:').white}"
            puts "   #{Rainbow(command_display).cyan}"
            puts ""
            puts "#{Rainbow('2.').cyan} #{Rainbow('Add --trace for full stack trace:').white}"
            puts "   #{Rainbow("#{command_display} --trace").cyan}"
            puts ""
            puts "#{Rainbow('3.').cyan} #{Rainbow("Or try with development #{active_assets_bundler} " \
                                                  '(faster, less optimized):').white}"
            puts "   #{Rainbow('NODE_ENV=development bundle exec rails assets:precompile').cyan}"
            puts ""

            puts Rainbow("💡 Common fixes:").yellow.bold

            # Provide specific guidance based on error content
            error_content = "#{stderr} #{stdout}".downcase

            if error_content.include?("secret_key_base")
              puts "#{Rainbow('•').yellow} #{Rainbow('Missing secret_key_base:').white.bold} " \
                   "Run #{Rainbow('bin/rails credentials:edit').cyan}"
            end

            if error_content.include?("database") || error_content.include?("relation") ||
               error_content.include?("table")
              puts "#{Rainbow('•').yellow} #{Rainbow('Database issues:').white.bold} " \
                   "Run #{Rainbow('bin/rails db:create db:migrate').cyan}"
            end

            if error_content.include?("gem") || error_content.include?("bundle") || error_content.include?("load error")
              puts "#{Rainbow('•').yellow} #{Rainbow('Missing dependencies:').white.bold} " \
                   "Run #{Rainbow('bundle install && npm install').cyan}"
            end

            if error_content.include?("webpack") || error_content.include?("rspack") ||
               error_content.include?("module") ||
               error_content.include?("compilation")
              puts "#{Rainbow('•').yellow} #{Rainbow("#{assets_bundler_label} compilation:").white.bold} " \
                   "Check JavaScript/#{active_assets_bundler} errors above"
            end

            # Always show these general options
            puts "#{Rainbow('•').yellow} #{Rainbow('Environment config:').white} " \
                 "Check #{Rainbow('config/environments/production.rb').cyan}"

            puts ""
            puts Rainbow("ℹ️  Alternative for development:").blue
            puts "   #{Rainbow('bin/dev static').green}  # Static assets without production optimizations"
            puts ""
            exit 1
          end
        end
        # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

        def run_static_development(procfile, verbose: false, route: nil, skip_database_check: false,
                                   open_browser: false, open_browser_once: false)
          # Check database setup before starting
          exit 1 unless DatabaseChecker.check_database(skip: skip_database_check)

          # Check required services before starting
          exit 1 unless ServiceChecker.check_services

          # Configure ports before printing so the banner shows the correct URL
          configure_ports
          print_procfile_info(procfile, route:)

          features = [
            "Using shakapacker --watch (no HMR)",
            "CSS extracted to separate files (no FOUC)",
            "Development environment (source maps, faster builds)",
            "Auto-recompiles on file changes"
          ]

          # Add pack generation info if not using precompile hook
          unless ReactOnRails::PackerUtils.shakapacker_precompile_hook_configured?
            features.unshift("Generating React on Rails packs")
          end

          print_server_info(
            "⚡ Starting development server with static assets...",
            features,
            procfile_port(procfile),
            route:
          )

          PackGenerator.generate(verbose:)
          ensure_default_port(procfile)
          schedule_browser_open_if_requested(procfile,
                                             route:,
                                             open_browser:,
                                             open_browser_once:)
          ProcessManager.ensure_procfile(procfile)
          ProcessManager.run_with_process_manager(procfile)
        end

        def run_development(procfile, verbose: false, route: nil, skip_database_check: false,
                            open_browser: false, open_browser_once: false)
          # Check database setup before starting
          exit 1 unless DatabaseChecker.check_database(skip: skip_database_check)

          # Check required services before starting
          exit 1 unless ServiceChecker.check_services

          # Configure ports before printing so the banner shows the correct URL
          configure_ports
          print_procfile_info(procfile, route:)

          PackGenerator.generate(verbose:)
          ensure_default_port(procfile)
          schedule_browser_open_if_requested(procfile,
                                             route:,
                                             open_browser:,
                                             open_browser_once:)
          ProcessManager.ensure_procfile(procfile)
          ProcessManager.run_with_process_manager(procfile)
        end

        def print_server_info(title, features, port = 3000, route: nil)
          puts title
          features.each { |feature| puts "   - #{feature}" }
          puts ""
          puts ""
          url = build_local_url(port, route)
          puts "💡 Access at: #{Rainbow(url).cyan.underline}"
          puts ""
        end

        def print_procfile_info(procfile, route: nil)
          port = procfile_port(procfile)
          box_width = 60
          url = build_local_url(port, route)

          puts ""
          puts box_border(box_width)
          puts box_empty_line(box_width)
          puts format_box_line("📋 Using Procfile: #{procfile}", box_width)
          puts format_box_line("🔧 Customize this file for your app's needs", box_width)
          puts box_empty_line(box_width)
          puts format_box_line("💡 Access at: #{Rainbow(url).cyan.underline}",
                               box_width)
          puts box_empty_line(box_width)
          puts box_bottom(box_width)
          puts ""
        end

        # NOTE: `run_production_like` does NOT use this method — it calls
        # `apply_base_port_if_active` directly because (1) its PORT auto-scan
        # starts at 3001, not 3000, and (2) in non-base-port mode it must not
        # set SHAKAPACKER_DEV_SERVER_PORT (no webpack-dev-server in prod-assets).
        # Base-port mode still sets SHAKAPACKER_DEV_SERVER_PORT (= base + 1) for
        # tooling consistency — see apply_base_port_env. Future `run_*` methods
        # should choose between the two entry points rather than adding a third
        # path.
        def configure_ports
          warn_if_legacy_renderer_url_env_used
          # Single call: select_ports! internally consults base_port_ports and
          # returns the same hash when base-port mode is active, so we branch
          # on :base_port_mode instead of calling base_port_ports twice.
          # Pass pro_renderer so OSS apps don't get a "port base+2 (renderer)
          # is already in use" warning for a port they don't actually use.
          selected = PortSelector.select_ports!(pro_renderer: pro_renderer_active?)
          if selected[:base_port_mode]
            apply_base_port_env(selected)
          else
            apply_explicit_port_env(selected)
          end
        rescue PortSelector::NoPortAvailable => e
          warn e.message
          exit 1
        end

        # Returns true if REACT_ON_RAILS_BASE_PORT / CONDUCTOR_PORT is active
        # and the derived env vars have been applied; false otherwise (env
        # untouched). Shared across development, static, and production-like
        # modes so all bin/dev entry points honor the same base-port contract.
        # Does not emit the legacy-RENDERER_URL warning — callers (or
        # configure_ports) do that so it fires in every mode regardless of
        # whether base-port mode is active.
        def apply_base_port_if_active
          selected = PortSelector.base_port_ports(pro_renderer: pro_renderer_active?)
          return false unless selected

          apply_base_port_env(selected)
          true
        end

        # The env var used to configure the Pro node renderer URL was renamed
        # from `RENDERER_URL` to `REACT_RENDERER_URL`. Two mid-migration states
        # are worth flagging:
        #
        #   1. Only `RENDERER_URL` is set — Rails falls back to the default
        #      `http://localhost:3800` silently (which doesn't exist in most
        #      container setups).
        #   2. Both are set but disagree — the Pro initializer and any tooling
        #      that reads one but not the other will silently disagree. The
        #      gem does not read either env var directly; the user's Pro
        #      initializer picks one (`config.renderer_url = ENV[...]`).
        def warn_if_legacy_renderer_url_env_used
          legacy = ENV.fetch("RENDERER_URL", nil)
          current = ENV.fetch("REACT_RENDERER_URL", nil)
          return if legacy.nil? || legacy.strip.empty?

          if current.nil? || current.strip.empty?
            warn "WARNING: RENDERER_URL is set but REACT_RENDERER_URL is not. " \
                 "RENDERER_URL was renamed to REACT_RENDERER_URL; update your " \
                 "env var to avoid silent fallback to the default renderer URL. " \
                 "Note: RENDERER_URL alone still activates the Pro renderer code " \
                 "path. Separately, if REACT_ON_RAILS_BASE_PORT or CONDUCTOR_PORT " \
                 "is set, base-port mode will derive RENDERER_PORT/REACT_RENDERER_URL " \
                 "from the base (overriding RENDERER_URL)."
            return
          end

          return if legacy.strip == current.strip

          warn "WARNING: RENDERER_URL=#{legacy.inspect} and REACT_RENDERER_URL=#{current.inspect} " \
               "are both set but disagree. RENDERER_URL was renamed to REACT_RENDERER_URL; " \
               "unset RENDERER_URL or align the two values so tooling and the Pro initializer " \
               "can't silently pick different renderer URLs."
        end

        # Base port is active. Priority: base port > explicit per-service env vars.
        # Assign unconditionally so the effective ports match the "Base port
        # detected..." log line even when PORT/RENDERER_PORT were pre-set.
        #
        # Base-port mode is specifically for local, all-in-one dev setups (one
        # machine running Rails + webpack + node renderer together — typically
        # worktrees or coding-agent sandboxes). The derived renderer URL keeps
        # an explicit localhost-equivalent scheme/host when present, and
        # otherwise falls back to http://localhost:<port>. If you run the node
        # renderer on a separate host/container (e.g. Docker `renderer:3800`),
        # do not use base-port mode — set REACT_RENDERER_URL explicitly and
        # rely on the explicit-ports path instead. warn_if_renderer_url_will_be_overridden
        # below surfaces the override whenever a pre-set URL doesn't match.
        #
        # SHAKAPACKER_DEV_SERVER_PORT is set even in production-like mode (which
        # runs static assets, not webpack-dev-server) for tooling consistency:
        # a subsequent `bin/dev` in the same shell sees the base-port-derived
        # value rather than a stale explicit one, and developers inspecting
        # their env after `bin/dev prod` see the full derived block.
        #
        # RENDERER_PORT / REACT_RENDERER_URL are gated on `pro_renderer_active?`
        # so OSS environments without the Pro node renderer don't get two
        # extra env vars in every child process. Pro users (gem loaded or env
        # vars already set) still get the derived block.
        def apply_base_port_env(selected)
          warn_if_port_will_be_overridden("PORT", selected[:rails])
          warn_if_port_will_be_overridden("SHAKAPACKER_DEV_SERVER_PORT", selected[:webpack])
          ENV["PORT"] = selected[:rails].to_s
          ENV["SHAKAPACKER_DEV_SERVER_PORT"] = selected[:webpack].to_s
          return unless pro_renderer_active?

          derived_url = base_port_renderer_url(selected[:renderer])
          warn_if_renderer_url_will_be_overridden("REACT_RENDERER_URL", derived_url)
          warn_if_port_will_be_overridden("RENDERER_PORT", selected[:renderer])
          ENV["RENDERER_PORT"] = selected[:renderer].to_s
          ENV["REACT_RENDERER_URL"] = derived_url
          # Keep legacy RENDERER_URL in sync only if the user already set it.
          # Pro initializers mid-migration may still read ENV["RENDERER_URL"];
          # leaving it pointed at the old port while the renderer process moves
          # to base+2 would silently route SSR calls to the wrong endpoint.
          # Skip when unset so we don't introduce the legacy name into envs
          # that have already migrated to REACT_RENDERER_URL.
          legacy_url = ENV.fetch("RENDERER_URL", nil)
          return if legacy_url.nil? || legacy_url.strip.empty?

          warn_if_renderer_url_will_be_overridden("RENDERER_URL", derived_url)
          ENV["RENDERER_URL"] = derived_url
        end

        def base_port_renderer_url(renderer_port)
          renderer_url = ENV.fetch("REACT_RENDERER_URL", nil).presence || ENV.fetch("RENDERER_URL", nil)

          local_base_port_renderer_url(renderer_url, renderer_port) ||
            "http://localhost:#{renderer_port}"
        end

        def local_base_port_renderer_url(url, renderer_port)
          return if url.nil? || url.strip.empty?

          parsed = URI.parse(url)
          return unless parsed.scheme && localhost_hostname?(parsed.hostname)

          URI::Generic.build(scheme: parsed.scheme, host: parsed.host, port: renderer_port).to_s
        rescue URI::Error
          nil
        end

        # Heuristic for "this app has a Pro node renderer to point at": either
        # the react_on_rails_pro gem is loaded, or the user has already set one
        # of the renderer env vars (so they're configuring a renderer manually
        # without the Pro gem). Keeps OSS environments clean while not
        # silently dropping renderer env for any caller who actually wants it.
        #
        # The legacy `RENDERER_URL` (renamed to `REACT_RENDERER_URL`) is
        # intentionally included so users mid-migration who still export
        # `RENDERER_URL` keep base-port renderer-derivation behavior. The
        # rename reminder lives in `warn_if_legacy_renderer_url_env_used`,
        # which calls out that the legacy var still triggers this path.
        def pro_renderer_active?
          return true if Gem.loaded_specs.key?("react_on_rails_pro")

          renderer_env_signal?
        end

        # Returns true when at least one renderer-pointing env var is set to a
        # non-blank value. Used both by `pro_renderer_active?` (to detect
        # Pro-renderer intent without the gem) and by
        # `configured_renderer_port_for_kill` (to avoid widening the kill
        # scope to 3800 when the Pro gem is loaded but no renderer was ever
        # configured). The legacy `RENDERER_URL` is included intentionally —
        # see `pro_renderer_active?` for the migration rationale.
        def renderer_env_signal?
          %w[RENDERER_PORT REACT_RENDERER_URL RENDERER_URL].any? do |var|
            value = ENV.fetch(var, nil)
            !value.nil? && !value.strip.empty?
          end
        end

        # Mirrors warn_if_renderer_url_will_be_overridden so users notice when a
        # pre-existing PORT or SHAKAPACKER_DEV_SERVER_PORT is replaced by the
        # base-port-derived value.
        #
        # Asymmetry vs. `overwrite_invalid_port_env` is intentional: base-port
        # mode replaces the user's explicit value with a derived one (so we
        # warn on any non-matching value), while explicit mode honors valid
        # user input and only warns when it must rewrite an invalid value.
        def warn_if_port_will_be_overridden(var_name, derived_port)
          existing = ENV.fetch(var_name, nil)
          return if existing.nil? || existing.strip.empty? || existing.strip == derived_port.to_s

          warn "WARNING: Overriding #{var_name}=#{existing.inspect} with #{derived_port} " \
               "because base port mode is active."
        end

        # Base port mode overrides REACT_RENDERER_URL (and the legacy
        # RENDERER_URL) to point at a local renderer derived from the base
        # port. Warn whenever an explicitly-set URL doesn't exactly match the
        # derived one so users notice — including the "localhost with a
        # different port" case, which is a real misconfiguration (Rails would
        # target one port, the renderer another).
        def warn_if_renderer_url_will_be_overridden(var_name, derived_url)
          existing = ENV.fetch(var_name, nil)
          return if existing.nil? || existing.strip.empty? || existing.strip == derived_url

          warn "WARNING: Overriding #{var_name}=#{existing.inspect} with #{derived_url} " \
               "because base port mode is active."
        end

        def apply_explicit_port_env(selected)
          # Overwrite whenever the current value is blank OR not a usable port
          # string. PortSelector.read_and_sanitize_port_env! has already
          # cleared invalid PORT / SHAKAPACKER_DEV_SERVER_PORT values upstream
          # (and emitted the "not a valid integer" warning there), so when
          # overwrite_invalid_port_env sees nil it silently writes the derived
          # port — the user-facing warning isn't missed, it fired at the
          # source. The Procfile's `${PORT:-3000}` fallback must not see a
          # stale `PORT=99999` or `PORT=abc` that would reach `rails s -p …`.
          overwrite_invalid_port_env("PORT", selected[:rails])
          overwrite_invalid_port_env("SHAKAPACKER_DEV_SERVER_PORT", selected[:webpack])
          sync_renderer_port_and_url
        end

        # Replace an invalid env value with the derived port, surfacing the
        # override so a user who set (e.g.) PORT=abc can see why it was ignored.
        # Silent when the env var is unset or already valid — explicit mode
        # honors a valid user-supplied port and only rewrites bad input.
        # Inverse of `warn_if_port_will_be_overridden`, which always rewrites
        # under base-port mode and warns on any non-matching value.
        def overwrite_invalid_port_env(var_name, derived_port)
          existing = ENV.fetch(var_name, nil)
          if valid_port_string?(existing)
            # Strip and write back so a whitespace-padded `" 3000 "` does not
            # leak into the Procfile's `${PORT:-3000}` expansion (which would
            # forward the spaces verbatim to `rails s -p`). Matches the
            # normalization already done for RENDERER_PORT in
            # sync_renderer_port_and_url.
            stripped = existing.strip
            ENV[var_name] = stripped if stripped != existing
            return
          end

          unless existing.nil? || existing.strip.empty?
            warn "WARNING: #{var_name}=#{existing.inspect} is not a valid port; " \
                 "using #{derived_port}."
          end
          ENV[var_name] = derived_port.to_s
        end

        def valid_port_string?(value)
          PortSelector.valid_port_string?(value)
        end

        def sync_renderer_port_and_url
          raw_port = ENV.fetch("RENDERER_PORT", nil)
          url = ENV.fetch("REACT_RENDERER_URL", nil)
          if raw_port.nil? || raw_port.strip.empty?
            warn_url_without_port(url)
            return
          end

          # Reuse the canonical port-string predicate so whitespace handling and
          # range checks match PortSelector exactly (`" 3800 "` is accepted
          # there; the inline regex here previously rejected it).
          unless valid_port_string?(raw_port)
            warn "WARNING: RENDERER_PORT=#{raw_port.inspect} is not a valid port (1..65535); ignoring."
            # Delete so the Procfile's `${RENDERER_PORT:-3800}` fallback applies
            # instead of passing the bad value through to the node renderer.
            ENV.delete("RENDERER_PORT")
            clear_local_renderer_url_after_invalid_port(url)
            return
          end

          # Normalize for downstream URL construction and mismatch checks so
          # `RENDERER_PORT=" 3800 "` doesn't leak whitespace into the derived
          # URL or the warning body. Also write the stripped value back to ENV
          # so the Procfile's `${RENDERER_PORT:-3800}` expansion propagates the
          # clean value to the node renderer subprocess instead of forwarding
          # the whitespace-padded original.
          port = raw_port.strip
          ENV["RENDERER_PORT"] = port if port != raw_port

          if url.nil? || url.strip.empty?
            # Only RENDERER_PORT set: derive the URL so Rails reaches the right port.
            # Use warn (stderr) so `bin/dev 2>/dev/null` silences this env-mutation
            # log together with every other "I changed your env" warning in this
            # file — stdout would leak through the same silencing attempt.
            derived = "http://localhost:#{port}"
            warn "WARNING: RENDERER_PORT=#{port} set without REACT_RENDERER_URL; " \
                 "deriving REACT_RENDERER_URL=#{derived}."
            ENV["REACT_RENDERER_URL"] = derived
          elsif url_port_mismatch?(url, port)
            # Both set but inconsistent — SSR will silently break otherwise.
            warn "WARNING: RENDERER_PORT=#{port} does not match REACT_RENDERER_URL=#{url}; " \
                 "Rails will use REACT_RENDERER_URL to reach the renderer. " \
                 "Unset one of them or ensure they agree."
          end
        end

        # URL without a port is a silent misconfig: the node renderer process
        # binds to the Procfile default (3800) while Rails targets whatever
        # port is in the URL. Warn so the mismatch is visible, but only for
        # local URLs where this process actually controls the renderer.
        #
        # Remote portless URLs (e.g. `REACT_RENDERER_URL=http://renderer.internal`)
        # are intentionally excluded: this process doesn't launch remote
        # renderers, so scheme-default ports (80/443) may be the correct target
        # behind a reverse proxy. Remote-side port mismatches are a deployment
        # concern, not something bin/dev can diagnose safely.
        def warn_url_without_port(url)
          return if url.nil? || url.strip.empty? || !localhost_renderer_url?(url)

          warn "WARNING: REACT_RENDERER_URL=#{url} is set without RENDERER_PORT. " \
               "The node renderer process may bind to a different port than Rails " \
               "expects. Set RENDERER_PORT to match the URL port."
        end

        # When a local renderer URL is paired with an invalid RENDERER_PORT,
        # keeping the URL would leave Rails targeting the stale port while the
        # Procfile falls back to 3800. Clear the URL so the initializer's
        # default localhost URL matches the renderer's fallback port.
        #
        # We clear unconditionally even when the user's URL port happens to
        # match the current Procfile default (e.g. http://localhost:3800):
        #   - The user expressed deliberate intent via RENDERER_PORT, which we
        #     could not honor. Falling through to the Procfile-default-driven
        #     URL keeps Rails and the renderer in sync regardless of which
        #     port the Procfile chooses now or later.
        #   - Any future change to the Procfile default would otherwise re-
        #     introduce a Rails/renderer mismatch silently for those users.
        def clear_local_renderer_url_after_invalid_port(url)
          return if url.nil? || url.strip.empty? || !localhost_renderer_url?(url)

          warn "WARNING: Clearing REACT_RENDERER_URL=#{url} because invalid " \
               "RENDERER_PORT was ignored; falling back to the default " \
               "localhost renderer port."
          ENV.delete("REACT_RENDERER_URL")
        end

        # Matches a URL with an explicit `:port` after the authority. Used by
        # `#url_port_mismatch?` to distinguish "URL has a port that disagrees"
        # from "URL has no port at all" (treated as a mismatch separately).
        #
        # Anatomy:
        #   - `(?:[^@/]*@)?` — optional userinfo prefix (`user:pass@`) so a URL
        #     like `http://user:3800@localhost` does not match the password as
        #     a host port via backtracking.
        #   - `(?:\[[^\]]+\]|[^@/:]+)` — host alternatives:
        #       * `\[[^\]]+\]` for bracketed IPv6 literals (`http://[::1]:3800`)
        #       * `[^@/:]+` for a regular hostname/IPv4 whose charset excludes
        #         `/` and `:` so the `:\d+` port anchor lands on the authority
        #         separator without backtracking into the host.
        URL_WITH_EXPLICIT_PORT_RE = %r{://(?:[^@/]*@)?(?:\[[^\]]+\]|[^@/:]+):\d+(?=[/?#]|$)}
        private_constant :URL_WITH_EXPLICIT_PORT_RE

        # Uses URI.parse so a short port isn't matched as a substring of a
        # longer one (e.g. ":80" inside ":3800"). Malformed URLs fall back to
        # "no mismatch detected" rather than crashing; the warn-path is only
        # advisory.
        #
        # Treats a URL without an explicit port as a mismatch: URI.parse would
        # otherwise return the scheme default (80 for http, 443 for https),
        # which would silently match `RENDERER_PORT=80` / `=443` — a misconfig
        # worth flagging rather than hiding.
        def url_port_mismatch?(url, port)
          return true unless url.match?(URL_WITH_EXPLICIT_PORT_RE)

          URI.parse(url).port != port.to_i
        rescue URI::InvalidURIError
          false
        end

        def localhost_renderer_url?(url)
          localhost_hostname?(URI.parse(url).hostname)
        rescue URI::InvalidURIError
          false
        end

        # Use `.hostname` not `.host`: for IPv6 URLs like `http://[::1]:3800`,
        # `.host` returns `"[::1]"` (with brackets) while `.hostname` returns
        # `"::1"` (bracket-stripped), matching the comparison list below.
        # Downcase: URI preserves host case, so `http://LOCALHOST:3900` would
        # otherwise be treated as non-local and skip the invalid-port URL
        # remediation path, leaving Rails targeting a stale port.
        def localhost_hostname?(hostname)
          %w[localhost 127.0.0.1 ::1].include?(hostname&.downcase)
        end

        # Callers are expected to have normalized ENV["PORT"] beforehand:
        # run_production_like clears non-integer / out-of-range values before
        # calling here, and the development/static paths route through
        # PortSelector.read_and_sanitize_port_env! which does the same. That
        # makes the `.to_i` below safe — a stray "abc" would otherwise become
        # 0 and scan from port 0.
        def procfile_port(procfile)
          if procfile == "Procfile.dev-prod-assets"
            ENV.fetch("PORT", 3001).to_i
          else
            ENV.fetch("PORT", 3000).to_i
          end
        end

        def ensure_default_port(procfile)
          return if ENV["PORT"].to_s.strip != ""

          ENV["PORT"] = procfile_port(procfile).to_s
        end

        def schedule_browser_open_if_requested(procfile, route:, open_browser:, open_browser_once:)
          return unless open_browser || open_browser_once

          # --open-browser is an explicit user request and bypasses TTY gating.
          # --open-browser-once is an auto-open and respects TTY/CI guards.
          explicit = open_browser && !open_browser_once
          schedule_browser_open(procfile_port(procfile), route:, once: open_browser_once,
                                                         explicit:)
        end

        def build_local_url(port, route)
          path = normalize_route_path(route)
          path = "" if path == "/"
          "http://localhost:#{port}#{path}"
        end

        def build_request_path(route)
          normalize_route_path(route)
        end

        def normalize_route_path(route)
          stripped = route.to_s.strip
          return "/" if stripped.empty? || stripped == "/"

          stripped = stripped.sub(%r{\A/+}, "")
          "/#{stripped}"
        end

        def schedule_browser_open(port, route:, once:, explicit: false)
          return unless browser_auto_open_allowed?(explicit:)

          url = build_local_url(port, route)
          request_path = build_request_path(route)
          Thread.new do
            if wait_for_app_route(port, request_path)
              marker_state = prepare_browser_open_once_marker(once)
              if marker_state != :already_opened && !open_browser(url)
                clear_browser_open_once_marker_if_claimed(marker_state)
                hint = if wsl?
                         " On WSL, install wslu (for wslview), wsl-open, or xdg-open."
                       elsif RbConfig::CONFIG["host_os"].include?("linux")
                         " Install xdg-utils (provides xdg-open) to enable automatic browser opening."
                       else
                         ""
                       end
                warn("[react_on_rails] Could not open browser automatically.#{hint} Visit #{url} manually.")
              end
            end
          rescue StandardError => e
            warn("[react_on_rails] Browser auto-open failed: #{e.message}")
          end
        end

        # Explicit user requests (--open-browser) bypass TTY/CI gating because the
        # developer deliberately asked for a browser open. Auto-opens
        # (--open-browser-once) respect the guards to avoid surprises in CI or
        # non-interactive shells.
        def browser_auto_open_allowed?(explicit: false)
          return true if explicit

          !ENV.key?("CI") && $stdin.tty? && $stdout.tty?
        end

        def wait_for_app_route(port, request_path)
          deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + OPEN_BROWSER_WAIT_TIMEOUT

          loop do
            return true if app_route_ready?(port, request_path)
            return false if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline

            sleep OPEN_BROWSER_POLL_INTERVAL
          end
        end

        LOCALHOST_ADDRESSES = %w[127.0.0.1 ::1].freeze
        private_constant :LOCALHOST_ADDRESSES

        def app_route_ready?(port, request_path)
          response = http_get_localhost(port, request_path)
          response.is_a?(Net::HTTPSuccess) || response.is_a?(Net::HTTPRedirection)
        end

        # Connection-level exceptions expected while the server is still booting.
        # Includes EOFError (premature close), Errno::EPIPE (dropped mid-request),
        # and Errno::EAFNOSUPPORT (IPv6 disabled) which are transient during startup.
        LOCALHOST_CONNECT_ERRORS = [
          Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::EHOSTUNREACH,
          Errno::ENETUNREACH, Errno::ETIMEDOUT, Errno::EADDRNOTAVAIL,
          Errno::EAFNOSUPPORT, Errno::EPIPE, EOFError,
          SocketError, Net::OpenTimeout, Net::ReadTimeout
        ].freeze
        private_constant :LOCALHOST_CONNECT_ERRORS

        def http_get_localhost(port, request_path)
          LOCALHOST_ADDRESSES.each do |host|
            response = Net::HTTP.start(host, port, open_timeout: 1, read_timeout: 1) do |http|
              http.get(request_path)
            end
            return response if response
          rescue *LOCALHOST_CONNECT_ERRORS
            next
          end
          nil
        end

        def open_browser(url)
          command = browser_command
          return false unless command

          system(*command, url, out: File::NULL, err: File::NULL)
        rescue StandardError
          false
        end

        def browser_command
          host_os = RbConfig::CONFIG["host_os"]
          return ["open"] if host_os.include?("darwin")

          return linux_browser_command if %w[linux bsd].any? { |platform| host_os.include?(platform) }

          # "start" requires a window title before the URL; the empty string is the
          # conventional placeholder so Windows opens the browser instead of treating
          # the URL as the title.
          return ["cmd", "/c", "start", ""] if %w[mswin mingw cygwin].any? { |platform| host_os.include?(platform) }

          nil
        end

        # WSL reports a Linux host_os but typically lacks xdg-open.
        # Try WSL-specific launchers first, then fall back to xdg-open.
        def linux_browser_command
          if wsl?
            return ["wslview"] if command_available?("wslview")
            return ["wsl-open"] if command_available?("wsl-open")
          end

          return ["xdg-open"] if command_available?("xdg-open")

          nil
        end

        def wsl?
          # WSL_DISTRO_NAME is the authoritative indicator (set by the WSL kernel).
          # WSLENV is a weaker signal — it can appear in non-WSL contexts (e.g. Docker
          # images that inherit a Windows host env) but is included as a fallback.
          ENV.key?("WSL_DISTRO_NAME") || ENV.key?("WSLENV")
        end

        def command_available?(command)
          ENV.fetch("PATH", "").split(File::PATH_SEPARATOR).any? do |directory|
            executable = File.join(directory, command)
            File.file?(executable) && File.executable?(executable)
          end
        end

        # Resolved lazily at call time so the path is correct even when this file
        # is required before the process has chdir'd into the Rails app root.
        def open_browser_once_marker
          File.join(Dir.pwd, "tmp", "react_on_rails", "browser_opened_once")
        end

        def prepare_browser_open_once_marker(once)
          return :not_requested unless once

          FileUtils.mkdir_p(File.dirname(open_browser_once_marker))
          File.open(open_browser_once_marker, File::WRONLY | File::CREAT | File::EXCL) do |marker|
            marker.write("#{Time.now.utc.iso8601}\n")
          end
          :claimed
        rescue Errno::EEXIST
          :already_opened
        rescue StandardError => e
          warn("[react_on_rails] Could not write browser-opened marker: #{e.message}")
          :untracked
        end

        def clear_browser_open_once_marker_if_claimed(marker_state)
          return unless marker_state == :claimed

          File.delete(open_browser_once_marker)
        rescue Errno::ENOENT
          nil
        rescue StandardError => e
          warn("[react_on_rails] Could not remove browser-opened marker: #{e.message}")
          nil
        end

        def box_border(width)
          "┌#{'─' * (width - 2)}┐"
        end

        def box_bottom(width)
          "└#{'─' * (width - 2)}┘"
        end

        def parse_cli_options(args)
          options = default_cli_options
          build_option_parser(options).parse!(args)
          options
        end

        def default_cli_options
          {
            route: nil,
            rails_env: nil,
            verbose: false,
            skip_database_check: false,
            test_watch_mode: "auto",
            open_browser: false,
            open_browser_once: false
          }
        end

        def build_option_parser(options)
          OptionParser.new do |opts|
            opts.banner = "Usage: dev [command] [options]"
            register_cli_flag_options(opts, options)
            register_browser_cli_options(opts, options)
            register_help_option(opts)
          end
        end

        def register_cli_flag_options(opts, options)
          opts.on("--route ROUTE", "Specify the route to display in URLs (default: root)") do |route|
            options[:route] = route
          end

          opts.on("--rails-env ENV", "Override RAILS_ENV for assets:precompile step only (prod mode only)") do |env|
            options[:rails_env] = env
          end

          opts.on("-v", "--verbose", "Enable verbose output for pack generation") do
            options[:verbose] = true
          end

          opts.on("--skip-database-check", "Skip database connectivity check (saves ~1-2s startup time)") do
            options[:skip_database_check] = true
          end

          opts.on("--test-watch-mode MODE", "For `bin/dev test-watch`: auto (default), full, or client-only") do |mode|
            options[:test_watch_mode] = mode
          end
        end

        def register_browser_cli_options(opts, options)
          # OptionParser applies flags left-to-right, so later browser flags intentionally
          # override earlier ones when callers pass multiple variants together.
          opts.on("--open-browser", "Open the app in your browser once the server is reachable") do
            options[:open_browser] = true
            options[:open_browser_once] = false
          end

          opts.on("--open-browser-once",
                  "Open the app in your browser after the first successful boot only") do
            options[:open_browser_once] = true
            options[:open_browser] = false
          end

          opts.on("--no-open-browser", "Disable automatic browser opening for this run") do
            options[:open_browser] = false
            options[:open_browser_once] = false
          end
        end

        def register_help_option(opts)
          opts.on("-h", "--help", "Prints this help") do
            show_help
            exit
          end
        end

        def box_empty_line(width)
          "│#{' ' * (width - 2)}│"
        end

        def format_box_line(content, box_width)
          line = "│ #{content}"
          # Use visual length for colored text
          visual_length = Rainbow.uncolor(line).length
          padding = box_width - visual_length - 2
          line + "#{' ' * padding}│"
        end

        # rubocop:disable Metrics/AbcSize
        def help_troubleshooting(default_mode)
          <<~TROUBLESHOOTING
            #{Rainbow('🔧 TROUBLESHOOTING:').cyan.bold}

            #{help_react_refresh_troubleshooting(default_mode).chomp}

            #{Rainbow('🚨 General Issues:').yellow.bold}
            #{Rainbow('•').red} #{Rainbow('"Port already in use"').white} #{Rainbow('→ Run:').yellow} #{Rainbow('bin/dev kill').green.bold}
            #{Rainbow('•').red} #{Rainbow("\"#{compilation_failed_label}\"").white} #{Rainbow('→ Check console for specific errors').white}
            #{Rainbow('•').red} #{Rainbow('"Process manager not found"').white} #{Rainbow('→ Install:').yellow} #{Rainbow('brew install overmind').green.bold} #{Rainbow('(or').white} #{Rainbow('gem install foreman').green.bold}#{Rainbow(')').white}
            #{Rainbow('•').red} #{Rainbow('"Assets not loading"').white} #{Rainbow('→ Verify Procfile.dev is present and check server logs').white}

            #{Rainbow('📖 DOCUMENTATION:').cyan.bold}
            #{documentation_link('Dev server modes & testing:', DEV_SERVER_AND_TESTING_DOCS_URL)}
            #{documentation_link('Test asset configuration:', TESTING_CONFIGURATION_DOCS_URL)}
            #{documentation_link('Full documentation:', "#{DOCS_BASE_URL}/")}
          TROUBLESHOOTING
        end
        # rubocop:enable Metrics/AbcSize

        def documentation_link(label, url)
          "#{Rainbow('•').yellow} #{Rainbow(label).white} #{Rainbow(url).cyan.underline}"
        end
      end
    end
  end
end

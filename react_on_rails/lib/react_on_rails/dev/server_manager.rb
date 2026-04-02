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
require "yaml"
require_relative "../packer_utils"
require_relative "database_checker"
require_relative "service_checker"

module ReactOnRails
  module Dev
    class ServerManager
      HELP_FLAGS = ["-h", "--help"].freeze
      TEST_WATCH_MODES = %w[auto full client-only].freeze
      OPEN_BROWSER_WAIT_TIMEOUT = 60
      OPEN_BROWSER_POLL_INTERVAL = 0.5
      # Relative to Dir.pwd; bin/dev is expected to run from the Rails app root.
      OPEN_BROWSER_ONCE_MARKER = File.join("tmp", "react_on_rails", "browser_opened_once").freeze

      class << self
        def start(mode = :development, procfile = nil, verbose: false, route: nil, rails_env: nil,
                  skip_database_check: false, open_browser: false, open_browser_once: false)
          case mode
          when :production_like
            run_production_like(_verbose: verbose, route: route, rails_env: rails_env,
                                skip_database_check: skip_database_check,
                                open_browser: open_browser,
                                open_browser_once: open_browser_once)
          when :static
            procfile ||= "Procfile.dev-static-assets"
            run_static_development(procfile, verbose: verbose, route: route,
                                             skip_database_check: skip_database_check,
                                             open_browser: open_browser,
                                             open_browser_once: open_browser_once)
          when :development, :hmr
            procfile ||= "Procfile.dev"
            run_development(procfile, verbose: verbose, route: route,
                                      skip_database_check: skip_database_check,
                                      open_browser: open_browser,
                                      open_browser_once: open_browser_once)
          else
            raise ArgumentError, "Unknown mode: #{mode}"
          end
        end

        def kill_processes
          puts "🔪 Killing all development processes..."
          puts ""

          killed_any = kill_running_processes || kill_port_processes([3000, 3001]) || cleanup_socket_files

          print_kill_summary(killed_any)
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
          files = [".overmind.sock", "tmp/sockets/overmind.sock", "tmp/pids/server.pid"]
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
          puts help_usage
          puts ""
          puts help_commands
          puts ""
          puts help_options
          puts ""
          puts help_customization
          puts ""
          puts help_mode_details
          puts ""
          puts help_troubleshooting
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

          # Run precompile hook once before starting any mode (except kill/help)
          # Then set environment variable to prevent duplicate execution in spawned processes.
          # Note: We always set SHAKAPACKER_SKIP_PRECOMPILE_HOOK=true (even when no hook is configured)
          # to provide a consistent signal that bin/dev is managing the precompile lifecycle.
          # This allows custom scripts to detect bin/dev's presence and adjust behavior accordingly.
          unless %w[kill help].include?(command) || help_requested
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
            env["CLIENT_BUNDLE_ONLY"] = "yes"
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
          server_only_watchers = find_process_pids("SERVER_BUNDLE_ONLY=yes bin/shakapacker --watch")
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

        def parsed_shakapacker_config
          config_path = ENV["SHAKAPACKER_CONFIG"] || "config/shakapacker.yml"
          return nil unless File.exist?(config_path)

          YAML.safe_load(ERB.new(File.read(config_path)).result, aliases: true, permitted_classes: [Symbol])
        rescue StandardError
          nil
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
        def help_commands
          <<~COMMANDS
            #{Rainbow('🚀 COMMANDS:').cyan.bold}
              #{Rainbow('(none) / hmr').green.bold}        #{Rainbow('Start development server with HMR (default)').white}
                                  #{Rainbow('→ Uses:').yellow} Procfile.dev

              #{Rainbow('static').green.bold}              #{Rainbow('Start development server with static assets (no HMR, no FOUC)').white}
                                  #{Rainbow('→ Uses:').yellow} Procfile.dev-static-assets

              #{Rainbow('production-assets').green.bold}   #{Rainbow('Start with production-optimized assets (no HMR)').white}
              #{Rainbow('prod').green.bold}                #{Rainbow('Alias for production-assets').white}
                                  #{Rainbow('→ Uses:').yellow} Procfile.dev-prod-assets

              #{Rainbow('test-watch').green.bold}          #{Rainbow('Watch and rebuild test assets with smart defaults').white}
                                  #{Rainbow('→ Uses:').yellow} bin/shakapacker --watch (RAILS_ENV=test)

              #{Rainbow('kill').red.bold}                #{Rainbow('Kill all development processes for a clean start').white}
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
        def help_customization
          <<~CUSTOMIZATION
            #{Rainbow('🔧 CUSTOMIZATION:').cyan.bold}
            Each mode uses a specific Procfile that you can customize for your application:

            #{Rainbow('•').yellow} #{Rainbow('Procfile.dev').green.bold}                 - HMR development with webpack-dev-server
            #{Rainbow('•').yellow} #{Rainbow('Procfile.dev-static-assets').green.bold}   - Static development with webpack --watch
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
            #{Rainbow('•').yellow} #{Rainbow('Use').white} #{Rainbow('bin/dev').green.bold} #{Rainbow('for HMR').white}
            #{Rainbow('•').yellow} #{Rainbow('Use').white} #{Rainbow('bin/dev test-watch').green.bold} #{Rainbow('to watch test assets').white}
            #{Rainbow('•').yellow} #{Rainbow('Override mode when needed:').white} #{Rainbow('--test-watch-mode=full').green.bold} #{Rainbow('or').white} #{Rainbow('--test-watch-mode=client-only').green.bold}

            #{Rainbow('Advanced static-only workflow (shared output):').white}
            #{Rainbow('•').yellow} #{Rainbow('Only use shared test/dev output with').white} #{Rainbow('bin/dev static').green.bold}
            #{Rainbow('•').yellow} #{Rainbow('Do not combine shared output path with').white} #{Rainbow('bin/dev').red.bold} #{Rainbow('(HMR)').white}

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
        def help_mode_details
          <<~MODES
            #{Rainbow('🔥 HMR Development mode (default)').cyan.bold} - #{Rainbow('Procfile.dev').green}:
            #{Rainbow('•').yellow} #{Rainbow('Hot Module Replacement (HMR) enabled').white}
            #{Rainbow('•').yellow} #{Rainbow('React on Rails pack generation (via precompile hook or bin/dev)').white}
            #{Rainbow('•').yellow} #{Rainbow('Webpack dev server for fast recompilation').white}
            #{Rainbow('•').yellow} #{Rainbow('Source maps for debugging').white}
            #{Rainbow('•').yellow} #{Rainbow('May have Flash of Unstyled Content (FOUC)').white}
            #{Rainbow('•').yellow} #{Rainbow('Fast recompilation').white}
            #{Rainbow('•').yellow} #{Rainbow('Access at:').white} #{Rainbow('http://localhost:3000/<route>').cyan.underline}

            #{Rainbow('📦 Static development mode').cyan.bold} - #{Rainbow('Procfile.dev-static-assets').green}:
            #{Rainbow('•').yellow} #{Rainbow('No HMR (static assets with auto-recompilation)').white}
            #{Rainbow('•').yellow} #{Rainbow('React on Rails pack generation (via precompile hook or bin/dev)').white}
            #{Rainbow('•').yellow} #{Rainbow('Webpack watch mode for auto-recompilation').white}
            #{Rainbow('•').yellow} #{Rainbow('CSS extracted to separate files (no FOUC)').white}
            #{Rainbow('•').yellow} #{Rainbow('Development environment (faster builds than production)').white}
            #{Rainbow('•').yellow} #{Rainbow('Source maps for debugging').white}
            #{Rainbow('•').yellow} #{Rainbow('Optional advanced testing: share output path with tests only in this mode').white}
            #{Rainbow('•').yellow} #{Rainbow('Access at:').white} #{Rainbow('http://localhost:3000/<route>').cyan.underline}

            #{Rainbow('🏭 Production-assets mode').cyan.bold} - #{Rainbow('Procfile.dev-prod-assets').green}:
            #{Rainbow('•').yellow} #{Rainbow('React on Rails pack generation (via precompile hook or assets:precompile)').white}
            #{Rainbow('•').yellow} #{Rainbow('Asset precompilation with NODE_ENV=production (webpack optimizations)').white}
            #{Rainbow('•').yellow} #{Rainbow('RAILS_ENV=development by default for assets:precompile (avoids credentials)').white}
            #{Rainbow('•').yellow} #{Rainbow('Use --rails-env=production for assets:precompile only (not server processes)').white}
            #{Rainbow('•').yellow} #{Rainbow('Server processes controlled by Procfile.dev-prod-assets environment').white}
            #{Rainbow('•').yellow} #{Rainbow('Optimized, minified bundles with CSS extraction').white}
            #{Rainbow('•').yellow} #{Rainbow('No HMR (static assets)').white}
            #{Rainbow('•').yellow} #{Rainbow('Access at:').white} #{Rainbow('http://localhost:3001/<route>').cyan.underline}
          MODES
        end
        # rubocop:enable Metrics/AbcSize

        # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
        def run_production_like(_verbose: false, route: nil, rails_env: nil, skip_database_check: false,
                                open_browser: false, open_browser_once: false)
          procfile = "Procfile.dev-prod-assets"

          # Set PORT before foreman starts — foreman injects its own PORT=5000
          # into child processes when ENV["PORT"] is unset, overriding the
          # ${PORT:-3001} fallback in the Procfile. Scan from 3001 (not 3000)
          # so prod-assets doesn't collide with the normal dev server.
          ENV["PORT"] ||= PortSelector.find_available_port(procfile_port(procfile)).to_s

          features = [
            "Precompiling assets with production optimizations",
            "Running Rails server on port #{procfile_port(procfile)}",
            "No HMR (Hot Module Replacement)",
            "CSS extracted to separate files (no FOUC)"
          ]

          # NOTE: Pack generation happens automatically during assets:precompile
          # either via precompile hook or via the configuration.rb adjust_precompile_task

          print_procfile_info(procfile, route: route)

          # Check database setup before starting
          exit 1 unless DatabaseChecker.check_database(skip: skip_database_check)

          # Check required services before starting
          exit 1 unless ServiceChecker.check_services

          print_server_info(
            "🏭 Starting production-like development server...",
            features,
            procfile_port(procfile),
            route: route
          )

          # Precompile assets with production webpack optimizations (includes pack generation automatically)
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

          puts "🔨 Precompiling assets with production webpack optimizations..."
          puts ""

          puts Rainbow("ℹ️  Asset Precompilation Environment:").blue
          puts "   • NODE_ENV=production → Webpack optimizations (minification, compression)"
          if rails_env
            puts "   • RAILS_ENV=#{rails_env} → Custom Rails environment for assets:precompile only"
            puts "   • Note: RAILS_ENV=production requires credentials, database setup, etc."
            puts "   • Server processes will use environment from Procfile.dev-prod-assets"
          else
            puts "   • RAILS_ENV=development → Simpler Rails setup (no credentials needed)"
            puts "   • Use --rails-env=production for assets:precompile step only"
            puts "   • Server processes will use environment from Procfile.dev-prod-assets"
            puts "   • Gets production webpack bundles without production Rails complexity"
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
                                               route: route,
                                               open_browser: open_browser,
                                               open_browser_once: open_browser_once)
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
            puts "#{Rainbow('3.').cyan} #{Rainbow('Or try with development webpack (faster, less optimized):').white}"
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

            if error_content.include?("webpack") || error_content.include?("module") ||
               error_content.include?("compilation")
              puts "#{Rainbow('•').yellow} #{Rainbow('Webpack compilation:').white.bold} " \
                   "Check JavaScript/webpack errors above"
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
          print_procfile_info(procfile, route: route)

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
            route: route
          )

          PackGenerator.generate(verbose: verbose)
          ensure_default_port(procfile)
          schedule_browser_open_if_requested(procfile,
                                             route: route,
                                             open_browser: open_browser,
                                             open_browser_once: open_browser_once)
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
          print_procfile_info(procfile, route: route)

          PackGenerator.generate(verbose: verbose)
          ensure_default_port(procfile)
          schedule_browser_open_if_requested(procfile,
                                             route: route,
                                             open_browser: open_browser,
                                             open_browser_once: open_browser_once)
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

        def configure_ports
          selected = PortSelector.select_ports
          ENV["PORT"] ||= selected[:rails].to_s
          ENV["SHAKAPACKER_DEV_SERVER_PORT"] ||= selected[:webpack].to_s
        rescue PortSelector::NoPortAvailable => e
          warn e.message
          exit 1
        end

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

          # --open-browser and --open-browser-once share scheduling, but only the latter writes
          # the marker so explicit --open-browser continues to open on each invocation.
          schedule_browser_open(procfile_port(procfile), route: route, once: open_browser_once)
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

        def schedule_browser_open(port, route:, once:)
          return unless browser_auto_open_allowed?

          url = build_local_url(port, route)
          request_path = build_request_path(route)
          Thread.new do
            Thread.current.report_on_exception = false if Thread.current.respond_to?(:report_on_exception=)
            next unless wait_for_app_route(port, request_path)

            marker_state = prepare_browser_open_once_marker(once)
            next if marker_state == :already_opened

            if open_browser(url)
              nil
            else
              clear_browser_open_once_marker_if_claimed(marker_state)
              warn("[react_on_rails] Could not open browser automatically. Visit #{url} manually.")
            end
          rescue StandardError => e
            warn("[react_on_rails] Browser auto-open failed: #{e.message}")
          end
        end

        def browser_auto_open_allowed?
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

        def http_get_localhost(port, request_path)
          LOCALHOST_ADDRESSES.each do |host|
            response = Net::HTTP.start(host, port, open_timeout: 1, read_timeout: 1) do |http|
              http.get(request_path)
            end
            return response if response
          rescue StandardError
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

          if %w[linux bsd].any? { |platform| host_os.include?(platform) } && command_available?("xdg-open")
            return ["xdg-open"]
          end

          # "start" requires a window title before the URL; the empty string is the
          # conventional placeholder so Windows opens the browser instead of treating
          # the URL as the title.
          return ["cmd", "/c", "start", ""] if %w[mswin mingw cygwin].any? { |platform| host_os.include?(platform) }

          nil
        end

        def command_available?(command)
          ENV.fetch("PATH", "").split(File::PATH_SEPARATOR).any? do |directory|
            executable = File.join(directory, command)
            File.file?(executable) && File.executable?(executable)
          end
        end

        def prepare_browser_open_once_marker(once)
          return :not_requested unless once

          FileUtils.mkdir_p(File.dirname(OPEN_BROWSER_ONCE_MARKER))
          File.open(OPEN_BROWSER_ONCE_MARKER, File::WRONLY | File::CREAT | File::EXCL) do |marker|
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

          File.delete(OPEN_BROWSER_ONCE_MARKER)
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
        def help_troubleshooting
          <<~TROUBLESHOOTING
            #{Rainbow('🔧 TROUBLESHOOTING:').cyan.bold}

            #{Rainbow('⚛️  React Refresh Issues:').yellow.bold}
            #{Rainbow('If you see "$RefreshSig$ is not defined" errors:').white}
            #{Rainbow('1.').green} #{Rainbow('Check that both babel plugin and webpack plugin are configured:').white}
               #{Rainbow('•').yellow} #{Rainbow('babel.config.js: \'react-refresh/babel\' plugin (enabled when WEBPACK_SERVE=true)').white}
               #{Rainbow('•').yellow} #{Rainbow('config/webpack/development.js: ReactRefreshWebpackPlugin (enabled when WEBPACK_SERVE=true)').white}
            #{Rainbow('2.').green} #{Rainbow('Ensure you\'re running HMR mode:').white} #{Rainbow('bin/dev').green.bold} #{Rainbow('(not').white} #{Rainbow('bin/dev static').red}#{Rainbow(')').white}
            #{Rainbow('3.').green} #{Rainbow('Try restarting the development server:').white} #{Rainbow('bin/dev kill && bin/dev').green.bold}
            #{Rainbow('4.').green} #{Rainbow('Note: React Refresh only works in HMR mode, not static mode').white}

            #{Rainbow('🚨 General Issues:').yellow.bold}
            #{Rainbow('•').red} #{Rainbow('"Port already in use"').white} #{Rainbow('→ Run:').yellow} #{Rainbow('bin/dev kill').green.bold}
            #{Rainbow('•').red} #{Rainbow('"Webpack compilation failed"').white} #{Rainbow('→ Check console for specific errors').white}
            #{Rainbow('•').red} #{Rainbow('"Process manager not found"').white} #{Rainbow('→ Install:').yellow} #{Rainbow('brew install overmind').green.bold} #{Rainbow('(or').white} #{Rainbow('gem install foreman').green.bold}#{Rainbow(')').white}
            #{Rainbow('•').red} #{Rainbow('"Assets not loading"').white} #{Rainbow('→ Verify Procfile.dev is present and check server logs').white}

            #{Rainbow('📖 DOCUMENTATION:').cyan.bold}
            #{Rainbow('•').yellow} #{Rainbow('Testing & dev server guide:').white} #{Rainbow('docs/oss/building-features/dev-server-and-testing.md').green}
            #{Rainbow('•').yellow} #{Rainbow('Testing configuration:').white} #{Rainbow('docs/oss/building-features/testing-configuration.md').green}
            #{Rainbow('•').yellow} #{Rainbow('Full docs:').white} #{Rainbow('https://reactonrails.com/docs/').cyan.underline}
          TROUBLESHOOTING
        end
        # rubocop:enable Metrics/AbcSize
      end
    end
  end
end

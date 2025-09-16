# frozen_string_literal: true

require "English"
require "open3"

module ReactOnRails
  module Dev
    class ServerManager
      class << self
        def start(mode = :development, procfile = nil, verbose: false)
          case mode
          when :production_like
            run_production_like(_verbose: verbose)
          when :static
            procfile ||= "Procfile.dev-static-assets"
            run_static_development(procfile, verbose: verbose)
          when :development, :hmr
            procfile ||= "Procfile.dev"
            run_development(procfile, verbose: verbose)
          else
            raise ArgumentError, "Unknown mode: #{mode}"
          end
        end

        def kill_processes
          puts "🔪 Killing all development processes..."
          puts ""

          killed_any = kill_running_processes || cleanup_socket_files

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
          rescue StandardError
            nil
          end
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

        private

        def help_usage
          "Usage: bin/dev [command] [options]"
        end

        def help_commands
          <<~COMMANDS
            Commands and their Procfiles:
              (none) / hmr        Start development server with HMR (default)
                                  → Uses: Procfile.dev

              static              Start development server with static assets (no HMR, no FOUC)
                                  → Uses: Procfile.dev-static-assets

              production-assets   Start with production-optimized assets (no HMR)
              prod                Alias for production-assets
                                  → Uses: Procfile.dev-prod-assets

              kill                Kill all development processes for a clean start
              help                Show this help message
          COMMANDS
        end

        def help_options
          <<~OPTIONS
            Options:
              --verbose, -v       Enable verbose output for pack generation
          OPTIONS
        end

        def help_customization
          <<~CUSTOMIZATION
            🔧 CUSTOMIZATION:
            Each mode uses a specific Procfile that you can customize for your application:

            • Procfile.dev                 - HMR development with webpack-dev-server
            • Procfile.dev-static-assets   - Static development with webpack --watch
            • Procfile.dev-prod-assets     - Production-optimized assets (port 3001)

            Edit these files to customize the development environment for your needs.
          CUSTOMIZATION
        end

        def help_mode_details
          <<~MODES
            HMR Development mode (default) - Procfile.dev:
            • Hot Module Replacement (HMR) enabled
            • React on Rails pack generation before Procfile start
            • Webpack dev server for fast recompilation
            • Source maps for debugging
            • May have Flash of Unstyled Content (FOUC)
            • Fast recompilation
            • Access at: http://localhost:3000

            Static development mode - Procfile.dev-static-assets:
            • No HMR (static assets with auto-recompilation)
            • React on Rails pack generation before Procfile start
            • Webpack watch mode for auto-recompilation
            • CSS extracted to separate files (no FOUC)
            • Development environment (faster builds than production)
            • Source maps for debugging
            • Access at: http://localhost:3000

            Production-assets mode - Procfile.dev-prod-assets:
            • React on Rails pack generation before Procfile start
            • Asset precompilation with production optimizations
            • Optimized, minified bundles
            • Extracted CSS files (no FOUC)
            • No HMR (static assets)
            • Slower recompilation
            • Access at: http://localhost:3001
          MODES
        end

        def run_production_like(_verbose: false)
          procfile = "Procfile.dev-prod-assets"

          print_procfile_info(procfile)
          print_server_info(
            "🏭 Starting production-like development server...",
            [
              "Generating React on Rails packs",
              "Precompiling assets with production optimizations",
              "Running Rails server on port 3001",
              "No HMR (Hot Module Replacement)",
              "CSS extracted to separate files (no FOUC)"
            ],
            3001
          )

          # Precompile assets in production mode (includes pack generation automatically)
          puts "🔨 Precompiling assets..."
          success = system "RAILS_ENV=production NODE_ENV=production bundle exec rails assets:precompile"

          if success
            puts "✅ Assets precompiled successfully"
            ProcessManager.ensure_procfile(procfile)
            ProcessManager.run_with_process_manager(procfile)
          else
            puts "❌ Asset precompilation failed"
            exit 1
          end
        end

        def run_static_development(procfile, verbose: false)
          print_procfile_info(procfile)
          print_server_info(
            "⚡ Starting development server with static assets...",
            [
              "Generating React on Rails packs",
              "Using shakapacker --watch (no HMR)",
              "CSS extracted to separate files (no FOUC)",
              "Development environment (source maps, faster builds)",
              "Auto-recompiles on file changes"
            ]
          )

          PackGenerator.generate(verbose: verbose)
          ProcessManager.ensure_procfile(procfile)
          ProcessManager.run_with_process_manager(procfile)
        end

        def run_development(procfile, verbose: false)
          print_procfile_info(procfile)
          PackGenerator.generate(verbose: verbose)
          ProcessManager.ensure_procfile(procfile)
          ProcessManager.run_with_process_manager(procfile)
        end

        def print_server_info(title, features, port = 3000)
          puts title
          features.each { |feature| puts "   - #{feature}" }
          puts ""
          puts "💡 Access at: http://localhost:#{port}"
          puts ""
        end

        def print_procfile_info(procfile)
          port = procfile_port(procfile)
          box_width = 60

          puts ""
          puts box_border(box_width)
          puts box_empty_line(box_width)
          puts format_box_line("📋 Using Procfile: #{procfile}", box_width)
          puts format_box_line("🔧 Customize this file for your app's needs", box_width)
          puts format_box_line("💡 Access at: http://localhost:#{port}", box_width)
          puts box_empty_line(box_width)
          puts box_bottom(box_width)
          puts ""
        end

        def procfile_port(procfile)
          procfile == "Procfile.dev-prod-assets" ? 3001 : 3000
        end

        def box_border(width)
          "┌#{'─' * (width - 2)}┐"
        end

        def box_bottom(width)
          "└#{'─' * (width - 2)}┘"
        end

        def box_empty_line(width)
          "│#{' ' * (width - 2)}│"
        end

        def format_box_line(content, box_width)
          line = "│ #{content}"
          padding = box_width - line.length - 2
          line + "#{' ' * padding}│"
        end

        def help_troubleshooting
          <<~TROUBLESHOOTING
            🔧 TROUBLESHOOTING:

            React Refresh Issues:
            If you see "$RefreshSig$ is not defined" errors:
            1. Check that both babel plugin and webpack plugin are configured:
               - babel.config.js: 'react-refresh/babel' plugin (enabled when WEBPACK_SERVE=true)
               - config/webpack/development.js: ReactRefreshWebpackPlugin (enabled when WEBPACK_SERVE=true)
            2. Ensure you're running HMR mode: bin/dev (not bin/dev static)
            3. Try restarting the development server: bin/dev kill && bin/dev
            4. Note: React Refresh only works in HMR mode, not static mode

            General Issues:
            • "Port already in use" → Run: bin/dev kill
            • "Webpack compilation failed" → Check console for specific errors
            • "Process manager not found" → Install: brew install overmind (or gem install foreman)
            • "Assets not loading" → Verify Procfile.dev is present and check server logs

            Need help? Visit: https://www.shakacode.com/react-on-rails/docs/
          TROUBLESHOOTING
        end
      end
    end
  end
end

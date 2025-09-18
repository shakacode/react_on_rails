# frozen_string_literal: true

require "English"
require "open3"
require "rainbow"

module ReactOnRails
  module Dev
    class ServerManager
      class << self
        def start(mode = :development, procfile = nil, verbose: false, route: nil)
          case mode
          when :production_like
            run_production_like(_verbose: verbose, route: route)
          when :static
            procfile ||= "Procfile.dev-static-assets"
            run_static_development(procfile, verbose: verbose, route: route)
          when :development, :hmr
            procfile ||= "Procfile.dev"
            run_development(procfile, verbose: verbose, route: route)
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

        def run_from_command_line(args = ARGV)
          require "optparse"

          options = { route: nil }

          OptionParser.new do |opts|
            opts.banner = "Usage: dev [command] [options]"

            opts.on("--route ROUTE", "Specify the route to display in URLs (default: root)") do |route|
              options[:route] = route
            end

            opts.on("-h", "--help", "Prints this help") do
              show_help
              exit
            end
          end.parse!(args)

          # Get the command (anything that's not parsed as an option)
          command = args[0]

          # Main execution
          case command
          when "production-assets", "prod"
            start(:production_like, nil, verbose: false, route: options[:route])
          when "static"
            start(:static, "Procfile.dev-static-assets", verbose: false, route: options[:route])
          when "kill"
            kill_processes
          when "help", "--help", "-h"
            show_help
          when "hmr", nil
            start(:development, "Procfile.dev", verbose: false, route: options[:route])
          else
            puts "Unknown argument: #{command}"
            puts "Run 'dev help' for usage information"
            exit 1
          end
        end

        private

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

              #{Rainbow('kill').red.bold}                #{Rainbow('Kill all development processes for a clean start').white}
              #{Rainbow('help').blue.bold}                #{Rainbow('Show this help message').white}
          COMMANDS
        end
        # rubocop:enable Metrics/AbcSize

        def help_options
          <<~OPTIONS
            #{Rainbow('⚙️  OPTIONS:').cyan.bold}
              #{Rainbow('--verbose, -v').green.bold}       #{Rainbow('Enable verbose output for pack generation').white}
          OPTIONS
        end

        def help_customization
          <<~CUSTOMIZATION
            #{Rainbow('🔧 CUSTOMIZATION:').cyan.bold}
            Each mode uses a specific Procfile that you can customize for your application:

            #{Rainbow('•').yellow} #{Rainbow('Procfile.dev').green.bold}                 - HMR development with webpack-dev-server
            #{Rainbow('•').yellow} #{Rainbow('Procfile.dev-static-assets').green.bold}   - Static development with webpack --watch
            #{Rainbow('•').yellow} #{Rainbow('Procfile.dev-prod-assets').green.bold}     - Production-optimized assets (port 3001)

            #{Rainbow('Edit these files to customize the development environment for your needs.').white}
          CUSTOMIZATION
        end

        # rubocop:disable Metrics/AbcSize
        def help_mode_details
          <<~MODES
            #{Rainbow('🔥 HMR Development mode (default)').cyan.bold} - #{Rainbow('Procfile.dev').green}:
            #{Rainbow('•').yellow} #{Rainbow('Hot Module Replacement (HMR) enabled').white}
            #{Rainbow('•').yellow} #{Rainbow('React on Rails pack generation before Procfile start').white}
            #{Rainbow('•').yellow} #{Rainbow('Webpack dev server for fast recompilation').white}
            #{Rainbow('•').yellow} #{Rainbow('Source maps for debugging').white}
            #{Rainbow('•').yellow} #{Rainbow('May have Flash of Unstyled Content (FOUC)').white}
            #{Rainbow('•').yellow} #{Rainbow('Fast recompilation').white}
            #{Rainbow('•').yellow} #{Rainbow('Access at:').white} #{Rainbow('http://localhost:3000/<route>').cyan.underline}

            #{Rainbow('📦 Static development mode').cyan.bold} - #{Rainbow('Procfile.dev-static-assets').green}:
            #{Rainbow('•').yellow} #{Rainbow('No HMR (static assets with auto-recompilation)').white}
            #{Rainbow('•').yellow} #{Rainbow('React on Rails pack generation before Procfile start').white}
            #{Rainbow('•').yellow} #{Rainbow('Webpack watch mode for auto-recompilation').white}
            #{Rainbow('•').yellow} #{Rainbow('CSS extracted to separate files (no FOUC)').white}
            #{Rainbow('•').yellow} #{Rainbow('Development environment (faster builds than production)').white}
            #{Rainbow('•').yellow} #{Rainbow('Source maps for debugging').white}
            #{Rainbow('•').yellow} #{Rainbow('Access at:').white} #{Rainbow('http://localhost:3000/<route>').cyan.underline}

            #{Rainbow('🏭 Production-assets mode').cyan.bold} - #{Rainbow('Procfile.dev-prod-assets').green}:
            #{Rainbow('•').yellow} #{Rainbow('React on Rails pack generation before Procfile start').white}
            #{Rainbow('•').yellow} #{Rainbow('Asset precompilation with production optimizations').white}
            #{Rainbow('•').yellow} #{Rainbow('Optimized, minified bundles').white}
            #{Rainbow('•').yellow} #{Rainbow('Extracted CSS files (no FOUC)').white}
            #{Rainbow('•').yellow} #{Rainbow('No HMR (static assets)').white}
            #{Rainbow('•').yellow} #{Rainbow('Slower recompilation').white}
            #{Rainbow('•').yellow} #{Rainbow('Access at:').white} #{Rainbow('http://localhost:3001/<route>').cyan.underline}
          MODES
        end
        # rubocop:enable Metrics/AbcSize

        def run_production_like(_verbose: false, route: nil)
          procfile = "Procfile.dev-prod-assets"

          print_procfile_info(procfile, route: route)
          print_server_info(
            "🏭 Starting production-like development server...",
            [
              "Generating React on Rails packs",
              "Precompiling assets with production optimizations",
              "Running Rails server on port 3001",
              "No HMR (Hot Module Replacement)",
              "CSS extracted to separate files (no FOUC)"
            ],
            3001,
            route: route
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
            puts ""
            puts "#{Rainbow('💡 Common fixes:').yellow.bold}"
            puts "#{Rainbow('•').yellow} #{Rainbow('Missing secret_key_base:').white} Run #{Rainbow('bin/rails credentials:edit').cyan}"
            puts "#{Rainbow('•').yellow} #{Rainbow('Database issues:').white} Run #{Rainbow('bin/rails db:create db:migrate').cyan}"
            puts "#{Rainbow('•').yellow} #{Rainbow('Missing dependencies:').white} Run #{Rainbow('bundle install && npm install').cyan}"
            puts "#{Rainbow('•').yellow} #{Rainbow('Webpack errors:').white} Check the error output above for specific issues"
            puts ""
            puts "#{Rainbow('ℹ️  For development with production-like assets, try:').blue}"
            puts "   #{Rainbow('bin/dev static').green}  # Static assets without production optimizations"
            puts ""
            exit 1
          end
        end

        def run_static_development(procfile, verbose: false, route: nil)
          print_procfile_info(procfile, route: route)
          print_server_info(
            "⚡ Starting development server with static assets...",
            [
              "Generating React on Rails packs",
              "Using shakapacker --watch (no HMR)",
              "CSS extracted to separate files (no FOUC)",
              "Development environment (source maps, faster builds)",
              "Auto-recompiles on file changes"
            ],
            route: route
          )

          PackGenerator.generate(verbose: verbose)
          ProcessManager.ensure_procfile(procfile)
          ProcessManager.run_with_process_manager(procfile)
        end

        def run_development(procfile, verbose: false, route: nil)
          print_procfile_info(procfile, route: route)
          PackGenerator.generate(verbose: verbose)
          ProcessManager.ensure_procfile(procfile)
          ProcessManager.run_with_process_manager(procfile)
        end

        def print_server_info(title, features, port = 3000, route: nil)
          puts title
          features.each { |feature| puts "   - #{feature}" }
          puts ""
          puts ""
          url = route ? "http://localhost:#{port}/#{route}" : "http://localhost:#{port}"
          puts "💡 Access at: #{Rainbow(url).cyan.underline}"
          puts ""
        end

        def print_procfile_info(procfile, route: nil)
          port = procfile_port(procfile)
          box_width = 60
          url = route ? "http://localhost:#{port}/#{route}" : "http://localhost:#{port}"

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

            #{Rainbow('📚 Need help? Visit:').blue.bold} #{Rainbow('https://www.shakacode.com/react-on-rails/docs/').cyan.underline}
          TROUBLESHOOTING
        end
        # rubocop:enable Metrics/AbcSize
      end
    end
  end
end

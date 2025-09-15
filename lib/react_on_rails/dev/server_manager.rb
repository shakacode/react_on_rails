# frozen_string_literal: true

require "English"

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

          processes = {
            "rails" => "Rails server",
            "node.*react[-_]on[-_]rails" => "React on Rails Node processes",
            "overmind" => "Overmind process manager",
            "foreman" => "Foreman process manager",
            "ruby.*puma" => "Puma server",
            "webpack-dev-server" => "Webpack dev server",
            "bin/shakapacker-dev-server" => "Shakapacker dev server"
          }

          killed_any = false

          processes.each do |pattern, description|
            pids = `pgrep -f "#{pattern}" 2>/dev/null`.split("\n").map(&:to_i).reject { |pid| pid == Process.pid }

            next unless pids.any?

            puts "   ☠️  Killing #{description} (PIDs: #{pids.join(', ')})"
            pids.each do |pid|
              Process.kill("TERM", pid)
            rescue StandardError
              nil
            end
            killed_any = true
          end

          # Clean up socket and pid files
          cleanup_files = [
            ".overmind.sock",
            "tmp/sockets/overmind.sock",
            "tmp/pids/server.pid"
          ]

          cleanup_files.each do |file|
            next unless File.exist?(file)

            puts "   🧹 Removing #{file}"
            begin
              File.delete(file)
            rescue StandardError
              nil
            end
            killed_any = true
          end

          if killed_any
            puts ""
            puts "✅ All processes terminated and sockets cleaned"
            puts "💡 You can now run 'bin/dev' for a clean start"
          else
            puts "   ℹ️  No development processes found running"
          end
        end

        def show_help
          puts <<~HELP
              Usage: bin/dev [command] [options]

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

              Options:
                --verbose, -v       Enable verbose output for pack generation
            #{'  '}
              🔧 CUSTOMIZATION:
              Each mode uses a specific Procfile that you can customize for your application:

              • Procfile.dev                 - HMR development with webpack-dev-server
              • Procfile.dev-static-assets   - Static development with webpack --watch
              • Procfile.dev-prod-assets     - Production-optimized assets (port 3001)

              Edit these files to customize the development environment for your needs.
            #{'  '}
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
          HELP
        end

        private

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
          # Determine port based on procfile
          port = procfile == "Procfile.dev-prod-assets" ? 3001 : 3000

          box_width = 60
          border = "┌#{'─' * (box_width - 2)}┐"
          bottom = "└#{'─' * (box_width - 2)}┘"

          procfile_line = "│ 📋 Using Procfile: #{procfile}"
          padding = box_width - procfile_line.length - 2
          procfile_line += "#{' ' * padding}│"

          access_line = "│ 💡 Access at: http://localhost:#{port}"
          padding = box_width - access_line.length - 2
          access_line += "#{' ' * padding}│"

          customize_line = "│ 🔧 Customize this file for your app's needs"
          padding = box_width - customize_line.length - 2
          customize_line += "#{' ' * padding}│"

          empty_line = "│#{' ' * (box_width - 2)}│"

          puts ""
          puts border
          puts empty_line
          puts procfile_line
          puts access_line
          puts customize_line
          puts empty_line
          puts bottom
          puts ""
        end
      end
    end
  end
end

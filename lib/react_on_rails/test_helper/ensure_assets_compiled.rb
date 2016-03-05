module ReactOnRails
  module TestHelper
    class EnsureAssetsCompiled
      SECONDS_TO_WAIT = 10

      class << self
        attr_accessor :has_been_run
        @has_been_run = false
      end

      attr_reader :webpack_assets_status_checker,
                  :webpack_assets_compiler,
                  :webpack_process_checker

      MAX_TIME_TO_WAIT = 5

      def initialize(webpack_assets_status_checker: nil,
                     webpack_assets_compiler: nil,
                     webpack_process_checker: nil)
        @webpack_assets_status_checker = webpack_assets_status_checker
        @webpack_assets_compiler = webpack_assets_compiler
        @webpack_process_checker = webpack_process_checker
      end

      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity

      # Several Scenarios:
      # 1. No webpack watch processes for static assets and files are mising or out of date.
      # 2. Only webpack watch process for server bundle as we're the  hot reloading setup.
      # 3. For whatever reason, the watch processes are running, but some clean script removed
      #    the generated bundles.
      def call
        # Only check this ONCE during a test run
        return if self.class.has_been_run

        # Be sure we don't do this again.
        self.class.has_been_run = true

        stale_gen_files = webpack_assets_status_checker.stale_generated_webpack_files

        # All done if no stale files!
        return if stale_gen_files.empty?

        # Inform the developer that we're ensuring gen assets are ready.
        puts_start_compile_check_message(stale_gen_files)

        hot_running = webpack_process_checker.hot_running?
        client_running = webpack_process_checker.client_running?
        server_running = webpack_process_checker.server_running?
        already_compiled_client_file = false

        # Check if running "hot" and not running a process to statically compile the client files.
        if hot_running && !client_running
          puts "Appears you're running hot reloading and are not rebuilding client files "\
            "automatically. We'll try rebuilding only your client files first."
          webpack_assets_compiler.compile_client(stale_gen_files)
          already_compiled_client_file = true

          stale_gen_files = webpack_assets_status_checker.stale_generated_webpack_files

          # Return if we're all done!
          return if stale_gen_files.empty?
        end

        loop_count = 0
        if (already_compiled_client_file && server_running) ||
           (!already_compiled_client_file && client_running)
          puts "Waiting #{SECONDS_TO_WAIT} for webpack watch processes to compile files"
          loop do
            sleep 1
            stale_gen_files = webpack_assets_status_checker.stale_generated_webpack_files
            loop_count += 1
            break if loop_count == SECONDS_TO_WAIT || stale_gen_files.empty?
          end
        end

        final_compilation_check(already_compiled_client_file, client_running, server_running, stale_gen_files)
      end

      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity

      def final_compilation_check(already_compiled_client_file, client_running, server_running, stale_gen_files)
        return unless stale_gen_files.present?
        if client_running || server_running
          puts <<-MSG
Arghhhhhh! We still have the following stale generated files after waiting for Webpack to compile:
#{stale_gen_files.join("\n")}

This can happen if you removed the generated files after they've been created by your webpack
watch processes, such by running a clean on your generated bundles before starting your tests.
          MSG
        end

        puts <<-MSG

If you are frequently running tests, you can run webpack in watch mode for static assets to
speed up this process. See the official documentation:
https://github.com/shakacode/react_on_rails/blob/master/docs/additional_reading/rspec_configuration.md
        MSG

        if already_compiled_client_file
          # So only do serer file
          webpack_assets_compiler.compile_server(stale_gen_files)
        else
          webpack_assets_compiler.compile_as_necessary(stale_gen_files)
        end
      end

      def puts_start_compile_check_message(stale_files)
        server_msg = Utils.server_rendering_is_enabled? ? "and `build:server`" : ""
        puts <<-MSG

Detected are the following stale generated files:
#{stale_files.join("\n")}

React on Rails will ensure your JavaScript generated files are up to date, using your
top level package.json `build:client` #{server_msg} commands.

        MSG
      end
    end
  end
end

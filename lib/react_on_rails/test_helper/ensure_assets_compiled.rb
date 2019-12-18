# frozen_string_literal: true

module ReactOnRails
  module TestHelper
    class EnsureAssetsCompiled
      class << self
        attr_accessor :has_been_run
        @has_been_run = false
      end

      attr_reader :webpack_assets_status_checker,
                  :webpack_assets_compiler

      def initialize(webpack_assets_status_checker: nil,
                     webpack_assets_compiler: nil)
        @webpack_assets_status_checker = webpack_assets_status_checker
        @webpack_assets_compiler = webpack_assets_compiler
      end

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

        ReactOnRails::LocalesToJs.new

        stale_gen_files = webpack_assets_status_checker.stale_generated_webpack_files

        # All done if no stale files!
        return if stale_gen_files.empty?

        # Inform the developer that we're ensuring gen assets are ready.
        puts_start_compile_check_message(stale_gen_files)

        webpack_assets_compiler.compile_assets
      end

      def puts_start_compile_check_message(stale_files)
        # rubocop:disable Layout/IndentHeredoc
        puts <<-MSG

Detected the following stale generated files:
  #{stale_files.join("\n  ")}

React on Rails will ensure your JavaScript generated files are up to date, using your
`#{ReactOnRails::Utils.prepend_cd_node_modules_directory(ReactOnRails.configuration.build_test_command)}` command.

        MSG
        # rubocop:enable Layout/IndentHeredoc
      end
    end
  end
end

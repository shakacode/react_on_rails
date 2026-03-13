# frozen_string_literal: true

module ReactOnRails
  module TestHelper
    class EnsureAssetsCompiled
      @has_been_run = false
      @mutex = Mutex.new

      class << self
        attr_accessor :has_been_run
        attr_reader :mutex
      end

      attr_reader :webpack_assets_status_checker,
                  :webpack_assets_compiler

      def initialize(webpack_assets_status_checker: nil,
                     webpack_assets_compiler: nil)
        @webpack_assets_status_checker = webpack_assets_status_checker
        @webpack_assets_compiler = webpack_assets_compiler
      end

      # Several Scenarios:
      # 1. No webpack watch processes for static assets and files are missing or out of date.
      # 2. Only webpack watch process for server bundle as we're the hot reloading setup.
      # 3. For whatever reason, the watch processes are running, but some clean script removed
      #    the generated bundles.
      # 4. bin/dev static is running with fresh assets → reuse dev output (no compilation).
      def call
        self.class.mutex.synchronize do
          # Only check this ONCE during a test run, even with threaded test runners.
          return if self.class.has_been_run

          self.class.has_been_run = true
        end

        ReactOnRails::Locales.compile

        stale_gen_files = webpack_assets_status_checker.stale_generated_webpack_files

        # All done if no stale files!
        return if stale_gen_files.empty?

        # If only the manifest is stale, check if development assets can be reused.
        # This handles the common case where bin/dev static is running and has
        # already compiled fresh assets. In that case, we can safely point
        # Shakapacker's test config at the dev output and skip test compilation.
        return if stale_gen_files.all? { |path| File.basename(path.to_s) == "manifest.json" } &&
                  DevAssetsDetector.try_activate_dev_assets!

        ReactOnRails::PacksGenerator.instance.generate_packs_if_stale if ReactOnRails.configuration.auto_load_bundle

        # Inform the developer that we're ensuring gen assets are ready.
        puts_start_compile_check_message(stale_gen_files)

        webpack_assets_compiler.compile_assets
      end

      def puts_start_compile_check_message(stale_files)
        puts <<~MSG

          React on Rails: Stale test assets detected:
            #{stale_files.join("\n  ")}

          Compiling with: `#{ReactOnRails::Utils.prepend_cd_node_modules_directory(ReactOnRails.configuration.build_test_command)}`

          Tip: To skip this wait, run 'bin/dev static' or 'bin/dev test-watch' in another terminal.
          See: #{WebpackAssetsCompiler::TESTING_DOCS_URL}

        MSG
      end
    end
  end
end

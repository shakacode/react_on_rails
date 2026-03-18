# frozen_string_literal: true

require_relative "generator_messages"

module ReactOnRails
  module Generators
    # Provides Pro setup functionality for React on Rails generators.
    #
    # This module extracts Pro-specific setup methods that can be shared between:
    # - InstallGenerator (when --pro or --rsc flags are used)
    # - ProGenerator (standalone generator for upgrading existing apps)
    #
    # == Required Dependencies
    # Including classes must provide (typically via Rails::Generators::Base):
    # - destination_root: Path to the target Rails application
    # - template, copy_file, append_to_file: Thor file manipulation methods
    # - options: Generator options hash
    #
    # Including classes must also include GeneratorHelper which provides:
    # - use_pro?, use_rsc?: Feature flag helpers
    # - pro_gem_installed?: Pro gem detection
    #
    # rubocop:disable Metrics/ModuleLength
    module ProSetup
      PRO_GEM_NAME = "react_on_rails_pro"
      # Version is appended dynamically via pro_gem_auto_install_command to ensure
      # the installed version matches the current react_on_rails gem version.
      AUTO_INSTALL_TIMEOUT = 120
      TERMINATION_GRACE_PERIOD = 5

      # Main entry point for Pro setup.
      # Orchestrates creation of all Pro-related files and configuration.
      #
      # Creates:
      # - config/initializers/react_on_rails_pro.rb
      # - client/node-renderer.js
      # - Procfile.dev entry for node-renderer
      #
      # @note NPM dependencies are handled separately by JsDependencyManager
      def setup_pro
        say "\n#{set_color('=' * 80, :cyan)}"
        say set_color("🚀 REACT ON RAILS PRO SETUP", :cyan, :bold)
        say set_color("=" * 80, :cyan)

        create_pro_initializer
        create_node_renderer
        add_pro_to_procfile
        update_webpack_config_for_pro

        say set_color("=" * 80, :cyan)
        say "✅ React on Rails Pro setup complete!", :green
        say set_color("=" * 80, :cyan)
      end

      # Check if Pro gem is missing. Attempts auto-install via bundle add.
      # @param force [Boolean] When true, always checks (default: only if use_pro?).
      # @return [Boolean] true if Pro gem is missing and could not be installed
      def missing_pro_gem?(force: false)
        return false unless force || use_pro?
        return false if pro_gem_installed?
        return false if attempt_pro_gem_auto_install

        context_line = if options.key?(:pro) || options.key?(:rsc)
                         flag = options[:rsc] ? "--rsc" : "--pro"
                         "You specified #{flag}, which requires the react_on_rails_pro gem."
                       else
                         "This generator requires the react_on_rails_pro gem."
                       end

        # TODO(#2575): Replace temporary email CTA after react-unrails.com flow is live.
        GeneratorMessages.add_error(<<~MSG.strip)
          🚫 Failed to auto-install #{PRO_GEM_NAME} gem.

          #{context_line}

          Please add manually to your Gemfile:
            gem '#{PRO_GEM_NAME}', '~> #{recommended_pro_gem_version}'

          Then run: bundle install

          No license needed for evaluation or non-production use.
          Free or low-cost production licenses available for startups and small companies.
          Get started: https://pro.reactonrails.com/
        MSG
        true
      end

      private

      # Attempt to auto-install the Pro gem via bundle add.
      # Uses Process.spawn instead of Timeout.timeout to avoid Thread#raise corrupting
      # Bundler.with_unbundled_env's ENV restoration.
      # @return [Boolean] true if the gem was successfully installed
      def attempt_pro_gem_auto_install
        say "📝 Adding #{PRO_GEM_NAME} to Gemfile...", :yellow

        status, output = run_bundle_add_with_captured_output
        return timeout_install_failure unless status

        say output unless output.to_s.strip.empty?
        return false unless status.success?

        # The gem is now in Gemfile/lockfile but not loaded in the current Ruby process.
        # Generator code that follows must not reference ReactOnRailsPro constants directly.
        mark_pro_gem_installed!
        true
      rescue StandardError => e
        say "⚠️  Failed to run bundle add: #{e.message}", :red
        false
      end

      def run_bundle_add_with_captured_output
        output_r, output_w = IO.pipe
        output_thread = nil

        begin
          pid = Bundler.with_unbundled_env do
            Process.spawn(pro_gem_auto_install_command, out: output_w, err: output_w)
          end
          output_w.close
          output_w = nil

          # Read in a thread to prevent pipe buffer deadlock.
          output_thread = Thread.new do
            output_r.read
          rescue IOError
            ""
          end

          status = wait_for_bundle_process(pid)
          output = output_thread.value
          [status, output]
        ensure
          output_w.close if output_w && !output_w.closed?
          output_r.close if output_r && !output_r.closed?
          output_thread&.join(0.1)
        end
      end

      def timeout_install_failure
        say "⏱️  bundle add timed out after #{AUTO_INSTALL_TIMEOUT} seconds.", :red
        false
      end

      # Wait for a process to finish, killing it if it exceeds AUTO_INSTALL_TIMEOUT.
      # @return [Process::Status, nil] status if process exited, nil if timed out
      def wait_for_bundle_process(pid)
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + AUTO_INSTALL_TIMEOUT
        loop do
          _pid, status = Process.wait2(pid, Process::WNOHANG)
          return status if status

          if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
            Process.kill("TERM", pid)
            term_deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + TERMINATION_GRACE_PERIOD
            loop do
              _term_pid, term_status = Process.wait2(pid, Process::WNOHANG)
              return nil if term_status
              break if Process.clock_gettime(Process::CLOCK_MONOTONIC) > term_deadline

              sleep 0.2
            end

            Process.kill("KILL", pid)
            Process.wait(pid)
            return nil
          end

          sleep 0.5
        end
      rescue Errno::ECHILD, Errno::ESRCH
        nil
      end

      def create_pro_initializer
        initializer_path = "config/initializers/react_on_rails_pro.rb"

        if File.exist?(File.join(destination_root, initializer_path))
          say "ℹ️  #{initializer_path} already exists, skipping", :yellow
          return
        end

        say "📝 Creating React on Rails Pro initializer...", :yellow

        template("templates/pro/base/config/initializers/react_on_rails_pro.rb.tt", initializer_path)

        say "✅ Created #{initializer_path}", :green
      end

      def create_node_renderer
        node_renderer_path = "client/node-renderer.js"

        if File.exist?(File.join(destination_root, node_renderer_path))
          say "ℹ️  #{node_renderer_path} already exists, skipping", :yellow
          return
        end

        say "📝 Creating Node Renderer bootstrap...", :yellow

        # Ensure client directory exists
        FileUtils.mkdir_p(File.join(destination_root, "client"))

        template_path = "templates/pro/base/client/node-renderer.js"
        copy_file(template_path, node_renderer_path)

        say "✅ Created #{node_renderer_path}", :green
      end

      def add_pro_to_procfile
        procfile_path = File.join(destination_root, "Procfile.dev")

        unless File.exist?(procfile_path)
          GeneratorMessages.add_warning(<<~MSG.strip)
            ⚠️  Procfile.dev not found. Skipping Node Renderer process addition.

            You'll need to add the Node Renderer to your process manager manually:
              node-renderer: RENDERER_LOG_LEVEL=debug RENDERER_PORT=3800 node client/node-renderer.js
          MSG
          return
        end

        if File.read(procfile_path).include?("node-renderer:")
          say "ℹ️  Node Renderer already in Procfile.dev, skipping", :yellow
          return
        end

        say "📝 Adding Node Renderer to Procfile.dev...", :yellow

        node_renderer_line = <<~PROCFILE

          # React on Rails Pro - Node Renderer for SSR
          node-renderer: RENDERER_LOG_LEVEL=debug RENDERER_PORT=3800 node client/node-renderer.js
        PROCFILE

        append_to_file("Procfile.dev", node_renderer_line)

        say "✅ Added Node Renderer to Procfile.dev", :green
      end

      # Update webpack configs to enable Pro settings.
      # This is needed for standalone Pro upgrades where the base install
      # created webpack configs without Pro settings enabled.
      #
      # Updates serverWebpackConfig.js:
      # - Adds extractLoader helper function (required by rscWebpackConfig.js)
      # - Adds Babel SSR caller setup (required for correct SSR compilation)
      # - Enables libraryTarget: 'commonjs2' (required for Node Renderer)
      # - Enables serverWebpackConfig.target = 'node' (required for Node.js modules)
      # - Disables Node.js polyfills via node = false (required for real __dirname)
      # - Changes module.exports to Pro style (required by rscWebpackConfig.js)
      #
      # Updates ServerClientOrBoth.js:
      # - Changes import to destructured style (required for Pro object export)
      def update_webpack_config_for_pro
        webpack_config, webpack_config_path = webpack_config_paths

        unless File.exist?(webpack_config_path)
          say "ℹ️  serverWebpackConfig.js not found, skipping webpack update", :yellow
          return
        end

        content = File.read(webpack_config_path)
        server_config_ready = pro_server_config_ready?(content)
        import_ready = server_client_import_ready?

        # Skip only when both server config and import style are already updated.
        if server_config_ready && import_ready
          say "ℹ️  Webpack config already has Pro settings enabled, skipping", :yellow
          return
        end

        say "📝 Updating serverWebpackConfig.js for Pro...", :yellow

        unless server_config_ready
          # Add extractLoader helper function after bundler require
          add_extract_loader_to_server_config(webpack_config, content)

          # Add Babel SSR caller setup (uses extractLoader, so must come after)
          add_babel_ssr_caller_to_server_config(webpack_config, content)

          # Uncomment libraryTarget: 'commonjs2'
          library_target_pattern = %r{// If using the React on Rails Pro.*\n\s*// libraryTarget: 'commonjs2',}
          library_target_replacement = "// Required for React on Rails Pro Node Renderer\n    " \
                                       "libraryTarget: 'commonjs2',"
          gsub_file(webpack_config, library_target_pattern, library_target_replacement)

          # Replace stale comments and uncomment target = 'node', add node = false
          # The base template has 4 lines: 2 explanatory comments + "uncomment" hint + commented code
          # Replace with clean Pro output matching the template's use_pro? branch
          # rubocop:disable Layout/LineLength
          target_node_pattern = %r{\s*// If using the default 'web',.*\n\s*// break with SSR\..*\n\s*// If using the React on Rails Pro.*\n\s*// serverWebpackConfig\.target = 'node'}
          # rubocop:enable Layout/LineLength
          target_node_replacement = "\n\n  " \
                                    "// React on Rails Pro uses Node renderer, so target must be 'node'\n  " \
                                    "// This fixes issues with libraries like Emotion and loadable-components\n  " \
                                    "serverWebpackConfig.target = 'node';\n\n  " \
                                    "// Disable Node.js polyfills - not needed when targeting Node\n  " \
                                    "serverWebpackConfig.node = false;"
          gsub_file(webpack_config, target_node_pattern, target_node_replacement)

          # Change module.exports to Pro style (exports object with default and extractLoader)
          update_server_config_exports(webpack_config)
        end

        # Update ServerClientOrBoth.js import style
        update_server_client_or_both_import

        verify_pro_webpack_transforms(webpack_config)
        say "✅ Updated webpack configs for Pro", :green
      end

      def webpack_config_paths
        config = destination_config_path("config/webpack/serverWebpackConfig.js")
        [config, File.join(destination_root, config)]
      end

      def add_extract_loader_to_server_config(webpack_config, content)
        # Skip if extractLoader already exists
        return if content.include?("function extractLoader")

        extract_loader_code = <<~JS.chomp


          function extractLoader(rule, loaderName) {
            if (!Array.isArray(rule.use)) return null;
            return rule.use.find((item) => {
              if (!item) return false;
              const testValue = typeof item === 'string' ? item : (typeof item.loader === 'string' ? item.loader : '');
              return testValue.includes(loaderName);
            });
          }
        JS

        # Insert after bundler require line
        gsub_file(
          webpack_config,
          %r{(const bundler = config\.assets_bundler.*\n.*require\('@rspack/core'\).*\n.*: require\('webpack'\);)},
          "\\1#{extract_loader_code}"
        )
      end

      def add_babel_ssr_caller_to_server_config(webpack_config, content)
        return if content.include?("babelLoader.options.caller")

        babel_ssr_code = "\n\n      " \
                         "// Set SSR caller for Babel (if using Babel instead of SWC)\n      " \
                         "const babelLoader = extractLoader(rule, 'babel-loader');\n      " \
                         "if (babelLoader && babelLoader.options) {\n        " \
                         "babelLoader.options.caller = { ssr: true };\n      " \
                         "}"

        # Insert after cssLoader.options.modules; [\s\S]*? covers both single-line and spread syntax patterns.
        gsub_file(
          webpack_config,
          /(cssLoader\.options\.modules = \{[\s\S]*?exportOnlyLocals: true[\s\S]*?\};\s*\n\s*\})/,
          "\\1#{babel_ssr_code}"
        )
        new_content = File.read(File.join(destination_root, webpack_config))
        return if new_content.include?("babelLoader.options.caller")

        say_status :warning, "Babel SSR caller insertion failed in #{webpack_config}; manual edit required.", :yellow
      end

      def update_server_config_exports(webpack_config)
        # Change from: module.exports = configureServer;
        # To: module.exports = { default: configureServer, extractLoader };
        gsub_file(
          webpack_config,
          /^module\.exports = configureServer;\s*$/,
          "module.exports = {\n  default: configureServer,\n  extractLoader,\n};\n"
        )
      end

      def verify_pro_webpack_transforms(webpack_config)
        content = File.read(File.join(destination_root, webpack_config))
        missing = missing_server_config_transforms(content)
        missing.concat(missing_server_client_import_transform)
        return if missing.empty?

        GeneratorMessages.add_warning(<<~MSG.strip)
          ⚠️  Some Pro webpack transforms may not have applied correctly.

          The following expected patterns were not found in #{webpack_config}:
          #{missing.map { |m| "  - #{m}" }.join("\n")}

          This can happen if your webpack config has been customized.
          Please verify #{webpack_config} manually.
        MSG
      end

      def missing_server_config_transforms(content)
        checks = [
          "libraryTarget: 'commonjs2',",
          "function extractLoader",
          "babelLoader.options.caller = { ssr: true }",
          "serverWebpackConfig.target = 'node'",
          "serverWebpackConfig.node = false",
          "default: configureServer",
          "extractLoader,"
        ]

        checks.reject { |pattern| content.include?(pattern) }
      end

      def missing_server_client_import_transform
        server_client_path = resolve_server_client_or_both_path
        return [] unless server_client_path

        content = File.read(File.join(destination_root, server_client_path))
        return [] if content.include?("{ default: serverWebpackConfig }")

        ["{ default: serverWebpackConfig }"]
      end

      def update_server_client_or_both_import
        server_client_path = resolve_server_client_or_both_path
        return unless server_client_path

        content = File.read(File.join(destination_root, server_client_path))

        # Skip if already using destructured import
        return if content.include?("{ default: serverWebpackConfig }")

        # Change from: const serverWebpackConfig = require('./serverWebpackConfig');
        # To: const { default: serverWebpackConfig } = require('./serverWebpackConfig');
        gsub_file(
          server_client_path,
          %r{^const serverWebpackConfig = require\('\./serverWebpackConfig'\);$},
          "const { default: serverWebpackConfig } = require('./serverWebpackConfig');"
        )

        new_content = File.read(File.join(destination_root, server_client_path))
        return if new_content.include?("{ default: serverWebpackConfig }")

        say_status(
          :warning,
          "ServerClientOrBoth import update failed in #{server_client_path}; manual edit required.",
          :yellow
        )
      end

      def pro_server_config_ready?(content)
        # Check for the Pro-specific comment marker (written by the transform) to avoid
        # false-negatives when commented-out lines also contain the pattern string.
        content.include?("// Required for React on Rails Pro Node Renderer") &&
          content.include?("function extractLoader") &&
          content.include?("babelLoader.options.caller = { ssr: true }") &&
          content.include?("serverWebpackConfig.target = 'node'") &&
          content.include?("serverWebpackConfig.node = false") &&
          content.include?("default: configureServer") &&
          content.include?("extractLoader,")
      end

      def server_client_import_ready?
        server_client_path = resolve_server_client_or_both_path
        return true unless server_client_path

        content = File.read(File.join(destination_root, server_client_path))
        content.include?("{ default: serverWebpackConfig }")
      end

      def pro_gem_auto_install_command
        "bundle add #{PRO_GEM_NAME} --version='~> #{recommended_pro_gem_version}' --strict"
      end

      # Keep manual fallback pinned to the latest stable release (drop pre-release suffixes like .rc.N).
      # react_on_rails_pro follows the same version number as react_on_rails by policy.
      # Both gems are released in lockstep; if this ever changes, replace with a dedicated constant.
      def recommended_pro_gem_version
        Gem::Version.new(ReactOnRails::VERSION).release.to_s
      rescue StandardError
        ReactOnRails::VERSION
      end
    end
    # rubocop:enable Metrics/ModuleLength
  end
end

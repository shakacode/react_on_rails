# frozen_string_literal: true

require "securerandom"
require_relative "generator_messages"
require "react_on_rails/node_renderer_procfile"
require "react_on_rails/pro_migration"

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
    # - pro_gem_installed?: Pro gem detection (real lockfile / loaded-specs state)
    # - pro_gem_install_deferred?, defer_pro_gem_install!: deferred-install tracking
    # - invalidate_pro_gem_installed_cache!: invalidate memoized pro_gem_installed?
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
      # - renderer/node-renderer.js
      # - Procfile.dev entry for node-renderer
      #
      # @note NPM dependencies are handled separately by JsDependencyManager
      def setup_pro
        say "\n#{set_color('=' * 80, :cyan)}"
        say set_color("🚀 REACT ON RAILS PRO SETUP", :cyan, :bold)
        say set_color("=" * 80, :cyan)

        # The Rails initializer and Node renderer bootstrap must share the same
        # password literal. Only mint a fresh random password when BOTH files will
        # be created — otherwise nil so each template falls back to the env-only
        # branch, avoiding a literal mismatch with any existing file.
        # Always reassign so a stale value from a prior invocation on the same
        # instance can't leak into a later partial-install run.
        @generated_renderer_password = nil
        if pro_initializer_will_be_created? && node_renderer_will_be_created?
          @generated_renderer_password = SecureRandom.hex(32)
        end

        initializer_created = create_pro_initializer
        legacy_renderer_detected = create_node_renderer
        add_pro_to_procfiles unless legacy_renderer_detected
        update_webpack_config_for_pro

        say_renderer_password_setup_summary(initializer_created)

        say set_color("=" * 80, :cyan)
        say "✅ React on Rails Pro setup complete!", :green
        say set_color("=" * 80, :cyan)
      end

      def say_renderer_password_setup_summary(initializer_created)
        if @generated_renderer_password
          say ""
          say set_color("🔐 A random renderer password was written into your config files.", :yellow, :bold)
          say "   For production, set RENDERER_PASSWORD as an env var instead and"
          say "   remove the literal value from version control."
          say "   See: https://www.shakacode.com/react-on-rails/docs/pro/node-renderer/"
          say ""
        elsif initializer_created
          # Initializer was newly created but the Node renderer file already exists;
          # the new initializer falls back to ENV["RENDERER_PASSWORD"] only so it doesn't
          # disagree with whatever literal the existing renderer file contains.
          say ""
          say set_color("⚠️  Existing Node renderer detected — Rails initializer uses " \
                        "ENV[\"RENDERER_PASSWORD\"] only.", :yellow, :bold)
          say "   Set RENDERER_PASSWORD in your environment to match the password in your existing renderer."
          say ""
        end
      end

      def pro_initializer_will_be_created?
        !File.exist?(File.join(destination_root, "config/initializers/react_on_rails_pro.rb"))
      end

      def node_renderer_will_be_created?
        !File.exist?(File.join(destination_root, "renderer/node-renderer.js")) &&
          !File.exist?(File.join(destination_root, "client/node-renderer.js"))
      end

      # Check if the Pro gem is missing. When the base react_on_rails gem is in
      # the Gemfile, installation is deferred to the later Gemfile swap (which
      # preserves the user's version pin); otherwise auto-install via `bundle
      # add` is attempted.
      # @param force [Boolean] When true, always checks (default: only if use_pro?).
      # @return [Boolean] true only if the Pro gem is missing and could not be
      #   installed; false if it is present, was auto-installed, or the install
      #   is deferred to the Gemfile swap.
      def missing_pro_gem?(force: false)
        return false unless force || use_pro?
        return false if pro_gem_installed? || pro_gem_install_deferred?
        return false if defer_pro_gem_install_to_gemfile_swap
        return false if attempt_pro_gem_auto_install

        optional_prerelease_line = prerelease_note.empty? ? "" : "\n#{prerelease_note}"

        GeneratorMessages.add_error(<<~MSG.strip)
          🚫 Failed to auto-install #{PRO_GEM_NAME} gem.

          #{pro_gem_requirement_context_line}#{optional_prerelease_line}

          Please add manually to your Gemfile:
            gem '#{PRO_GEM_NAME}', '#{pro_gem_version_requirement}'

          Then run: bundle install

          No license needed for evaluation or non-production use.
          Free or low-cost production licenses available for startups and small companies.
          See the upgrade guide: https://reactonrails.com/docs/pro/upgrading-to-pro/
        MSG
        true
      end

      private

      def pro_gem_requirement_context_line
        return "This generator requires the react_on_rails_pro gem." unless pro_flag_specified_for_context?

        "You specified #{pro_requirement_flag}, which requires the react_on_rails_pro gem."
      end

      def pro_flag_specified_for_context?
        use_pro?
      end

      def pro_requirement_flag
        return "--rsc" if options[:rsc]

        "--pro"
      end

      def prerelease_note
        return "" unless prerelease_ror_version?

        "Note: #{PRO_GEM_NAME} #{ReactOnRails::VERSION} may not be published yet. " \
          "If you are testing from source, use a local Gemfile `path:` option."
      end

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
        # The lockfile changed, so the memoized pro_gem_installed? must be refreshed.
        invalidate_pro_gem_installed_cache!
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
          return false
        end

        say "📝 Creating React on Rails Pro initializer...", :yellow

        # @generated_renderer_password is set by setup_pro only when both this
        # file and the Node renderer bootstrap will be created together; nil here
        # means the template emits the env-only fallback (no literal password).
        template("templates/pro/base/config/initializers/react_on_rails_pro.rb.tt", initializer_path)

        say "✅ Created #{initializer_path}", :green
        true
      end

      # Matches active (uncommented) Procfile.dev node-renderer lines that
      # both set RENDERER_PORT and launch renderer/node-renderer.js (optionally
      # prefixed with `./`). Entries missing RENDERER_PORT are intentionally
      # not matched here so they fall through to NODE_RENDERER_PROCESS_REGEX
      # and surface the "Update it manually" warning, keeping the generator's
      # accept/skip decision aligned with the doctor's RENDERER_PORT check in
      # NodeRendererProcfile::PROCESS_WITH_RENDERER_PORT_REGEX.
      NEW_RENDERER_COMMAND_REGEX = %r{
        ^[ \t]*(?:node-)?renderer:
        (?=[^\n]*\bRENDERER_PORT\b)
        [^\n]*\bnode\s+\.?/?renderer/node-renderer\.js\b
      }x
      LEGACY_RENDERER_COMMAND_REGEX = %r{^[ \t]*(?:node-)?renderer:[^\n]*\bnode\s+\.?/?client/node-renderer\.js\b}
      # Detects an existing Node Renderer process entry. The dedicated
      # `node-renderer:` label is reserved for the Pro Node Renderer, so any
      # entry with that label is treated as the user's renderer regardless of
      # the command (avoiding duplicate-label appends). A bare `renderer:`
      # label could be anything (e.g. `renderer: vite ...`), so it only counts
      # when the command actually launches a node-renderer — otherwise the
      # generator would emit a misleading "update it manually" warning for an
      # unrelated process.
      NODE_RENDERER_PROCESS_REGEX = %r{
        ^[ \t]*(?:
          node-renderer:
          |
          renderer:[^\n]*(?:
            \bnode\s+\.?/?(?:renderer|client)/node-renderer\.js\b
            |
            \b(?:pnpm|npm|yarn)\s+(?:run\s+)?node-renderer\b
          )
        )
      }x
      # Creates renderer/node-renderer.js unless either the new path or the legacy
      # client/node-renderer.js already exists.
      #
      # @return [Boolean] true when a legacy client/node-renderer.js was detected
      #   (caller should skip add_pro_to_procfiles to avoid pointing Procfile.dev
      #   at a file that wasn't created); false otherwise.
      def create_node_renderer
        node_renderer_path = "renderer/node-renderer.js"
        legacy_node_renderer_path = "client/node-renderer.js"

        if File.exist?(File.join(destination_root, node_renderer_path))
          say "ℹ️  #{node_renderer_path} already exists, skipping", :yellow
          return false
        end

        if File.exist?(File.join(destination_root, legacy_node_renderer_path))
          say "ℹ️  #{legacy_node_renderer_path} detected, keeping existing renderer; " \
              "to migrate, move it to #{node_renderer_path} and update any references " \
              "(e.g. Procfile.dev, Procfile.prod, Docker CMD / command):", :yellow
          say "      #{node_renderer_procfile_command('Procfile.dev')}", :yellow
          say set_color(
            "⚠️  Ensure the password in #{legacy_node_renderer_path} matches " \
            "config/initializers/react_on_rails_pro.rb. Both must use the same RENDERER_PASSWORD.",
            :yellow
          )
          warn_on_stale_legacy_procfile_entry
          return true
        end

        say "📝 Creating Node Renderer bootstrap...", :yellow

        empty_directory("renderer")

        template_path = "templates/pro/base/renderer/node-renderer.js.tt"
        template(template_path, node_renderer_path)

        say "✅ Created #{node_renderer_path}", :green
        false
      end

      # When a legacy client/node-renderer.js is detected, add_pro_to_procfiles is
      # skipped, so surface a pointed warning for each Procfile that still
      # launches the legacy entry. This nudges the user to update the exact
      # line(s) they need to touch rather than leaving them to diff the generic
      # migration hint against their Procfiles themselves.
      def warn_on_stale_legacy_procfile_entry
        ReactOnRails::NodeRendererProcfile::DEFAULT_COMMANDS.each_key do |procfile|
          procfile_path = File.join(destination_root, procfile)
          next unless File.exist?(procfile_path)

          procfile_content = File.read(procfile_path)
          next unless procfile_content.match?(LEGACY_RENDERER_COMMAND_REGEX)

          GeneratorMessages.add_warning(<<~MSG.strip)
            ⚠️  #{procfile} still launches the legacy client/node-renderer.js.
            After migrating the renderer file, update that line to:
              #{node_renderer_procfile_command(procfile)}
          MSG
        end
      end

      def node_renderer_procfile_command(procfile)
        ReactOnRails::NodeRendererProcfile.command_for(procfile)
      end

      def add_pro_to_procfiles
        ReactOnRails::NodeRendererProcfile::DEFAULT_COMMANDS.each do |procfile, command|
          add_node_renderer_to_procfile(procfile, command, warn_if_missing: procfile == "Procfile.dev")
        end
      end

      def add_node_renderer_to_procfile(procfile, command, warn_if_missing:)
        procfile_path = File.join(destination_root, procfile)

        unless File.exist?(procfile_path)
          return unless warn_if_missing

          GeneratorMessages.add_warning(<<~MSG.strip)
            ⚠️  #{procfile} not found. Skipping Node Renderer process addition.

            You'll need to add the Node Renderer to your process manager manually:
              #{command}
          MSG
          return
        end

        procfile_content = File.read(procfile_path)

        if procfile_content.match?(NEW_RENDERER_COMMAND_REGEX)
          say "ℹ️  Node Renderer already in #{procfile}, skipping", :yellow
          return
        end

        if procfile_content.match?(NODE_RENDERER_PROCESS_REGEX)
          say "⚠️  #{procfile} has a renderer entry that doesn't reference " \
              "renderer/node-renderer.js. Update it manually to:", :yellow
          say "      #{command}", :yellow
          return
        end

        say "📝 Adding Node Renderer to #{procfile}...", :yellow

        node_renderer_line = <<~PROCFILE

          # React on Rails Pro - Node Renderer for SSR
          #{command}
        PROCFILE

        append_to_file(procfile, node_renderer_line)

        say "✅ Added Node Renderer to #{procfile}", :green
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
        "bundle add #{PRO_GEM_NAME} --version='#{pro_gem_version_requirement}' --strict"
      end

      def defer_pro_gem_install_to_gemfile_swap
        return false unless base_react_on_rails_gem_in_gemfile?

        defer_pro_gem_install!
        true
      end

      def base_react_on_rails_gem_in_gemfile?
        gemfile_path = File.join(destination_root, "Gemfile")
        return false unless File.exist?(gemfile_path)

        ReactOnRails::ProMigration.base_gem_entry?(File.read(gemfile_path))
      rescue SystemCallError, IOError
        false
      end

      def pro_gem_version_requirement
        # Prerelease gem versions need an exact pin: Bundler's pessimistic operator
        # (~>) does not match prerelease versions, so a stable range would fail to
        # install during prerelease cycles.
        return ReactOnRails::VERSION if prerelease_ror_version?

        "~> #{recommended_pro_gem_version}"
      end

      def prerelease_ror_version?
        Gem::Version.new(ReactOnRails::VERSION).prerelease?
      rescue ArgumentError
        false
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

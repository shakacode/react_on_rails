# frozen_string_literal: true

require_relative "generator_messages"
require_relative "demo_page_config"

module ReactOnRails
  module Generators
    # Provides RSC (React Server Components) setup functionality for React on Rails generators.
    #
    # This module extracts RSC-specific setup methods that can be shared between:
    # - InstallGenerator (when --rsc flag is used)
    # - RscGenerator (standalone generator for upgrading existing Pro apps)
    #
    # == Required Dependencies
    # Including classes must provide (typically via Rails::Generators::Base):
    # - destination_root: Path to the target Rails application
    # - template, copy_file, append_to_file, empty_directory, route: Thor file manipulation methods
    # - options: Generator options hash (for options.typescript?)
    #
    # Including classes must also include GeneratorHelper which provides:
    # - use_rsc?: Feature flag helper
    # - component_extension: Returns 'jsx' or 'tsx' based on TypeScript option
    # - detect_react_version: Detects installed React version
    #
    module RscSetup # rubocop:disable Metrics/ModuleLength
      include DemoPageConfig

      DEFAULT_LAYOUT_NAME = "react_on_rails_default"
      LEGACY_LAYOUT_NAME = "hello_world"
      RSC_FALLBACK_LAYOUT_NAME = "react_on_rails_rsc"
      RSC_GENERATED_LAYOUT_NAME_PATTERN = /\Areact_on_rails_rsc(?:_(?:[2-9]|[1-9]\d+))?\z/
      MAX_LAYOUT_NAME_ATTEMPTS = 99
      JS_STRING_DELIMITERS = ["'", '"', "`"].freeze
      JS_COMMENT_STATES = %i[line_comment block_comment].freeze

      # Main entry point for RSC setup.
      # Orchestrates creation of all RSC-related files and configuration.
      #
      # Creates:
      # - config/webpack/rscWebpackConfig.js (config/rspack/ when using rspack)
      # - Procfile.dev entry for RSC bundle watcher
      # - HelloServer component (jsx or tsx based on --typescript flag)
      # - HelloServerController
      # - HelloServer view
      # - RSC routes
      #
      # @note NPM dependencies are handled separately by JsDependencyManager
      def setup_rsc
        print_rsc_setup_banner

        add_rsc_config_to_pro_initializer
        create_rsc_webpack_config
        update_webpack_configs_for_rsc
        add_rsc_to_procfile
        create_hello_server_component
        create_hello_server_controller
        create_hello_server_view
        add_rsc_routes

        print_rsc_complete_banner
      end

      # Warn if React version is not compatible with RSC.
      # RSC requires React 19.0.x specifically (not 19.1.x or later).
      #
      # @param force [Boolean] When true, always performs the check.
      #   When false (default), only checks if RSC is enabled (use_rsc? returns true).
      #   Use force: true in standalone generators where RSC is always the purpose.
      def warn_about_react_version_for_rsc(force: false)
        return unless force || use_rsc?

        react_version = detect_react_version
        return if react_version.nil? # React not installed yet, will be installed by generator

        major, minor, patch = react_version.split(".").map(&:to_i)

        if major != 19 || minor != 0
          GeneratorMessages.add_warning(<<~MSG.strip)
            ⚠️  RSC requires React 19.0.x (detected: #{react_version})

            React Server Components in React on Rails Pro currently only supports
            React 19.0.x. React 19.1.x and later are not yet supported.

            To install a compatible React version:
              npm install react@~19.0.4 react-dom@~19.0.4
          MSG
        elsif patch < 4
          GeneratorMessages.add_warning(<<~MSG.strip)
            ⚠️  React #{react_version} is below the recommended minimum for RSC.

            Please upgrade to at least React 19.0.4:
              npm install react@19.0.4 react-dom@19.0.4

            react-server-dom-webpack 19.0.0–19.0.3 has known vulnerabilities
            (CVE-2025-55182, CVE-2025-67779, CVE-2026-23864) fixed in 19.0.4+.
          MSG
        end
      end

      private

      def add_rsc_config_to_pro_initializer
        initializer_path = "config/initializers/react_on_rails_pro.rb"
        full_path = File.join(destination_root, initializer_path)

        unless File.exist?(full_path)
          GeneratorMessages.add_warning(<<~MSG.strip)
            ⚠️  Pro initializer not found at #{initializer_path}. Skipping RSC config.

            RSC requires React on Rails Pro. Run the Pro generator first:
              rails g react_on_rails:pro
          MSG
          return
        end

        content = File.read(full_path)

        if content.include?("enable_rsc_support")
          say "ℹ️  RSC config already in Pro initializer, skipping", :yellow
          return
        end

        say "📝 Adding RSC config to Pro initializer...", :yellow

        rsc_config = <<-CONFIG

  # React Server Components configuration
  config.enable_rsc_support = true
  config.rsc_bundle_js_file = "rsc-bundle.js"
  config.rsc_payload_generation_url_path = "rsc_payload/"
        CONFIG

        # Insert before the final 'end'
        gsub_file(initializer_path, /^end\s*\z/, "#{rsc_config}end")

        say "✅ Added RSC config to #{initializer_path}", :green
      end

      def print_rsc_setup_banner
        say "\n#{set_color('=' * 80, :magenta)}"
        say set_color("🚀 REACT SERVER COMPONENTS SETUP", :magenta, :bold)
        say set_color("=" * 80, :magenta)
      end

      def print_rsc_complete_banner
        say set_color("=" * 80, :magenta)
        say "✅ React Server Components setup complete!", :green
        say set_color("=" * 80, :magenta)
      end

      def create_rsc_webpack_config
        webpack_config_path = destination_config_path("config/webpack/rscWebpackConfig.js")

        if File.exist?(File.join(destination_root, webpack_config_path))
          say "ℹ️  #{webpack_config_path} already exists, skipping", :yellow
          return
        end

        say "📝 Creating RSC webpack config...", :yellow

        rsc_template_path = "templates/rsc/base/config/webpack/rscWebpackConfig.js.tt"
        template(rsc_template_path, webpack_config_path)

        say "✅ Created #{webpack_config_path}", :green
      end

      def add_rsc_to_procfile
        procfile_path = File.join(destination_root, "Procfile.dev")

        unless File.exist?(procfile_path)
          GeneratorMessages.add_warning(<<~MSG.strip)
            ⚠️  Procfile.dev not found. Skipping RSC bundle watcher addition.

            You'll need to add the RSC bundle watcher to your process manager manually:
              rsc-bundle: RSC_BUNDLE_ONLY=true bin/shakapacker-watch --watch
          MSG
          return
        end

        if File.read(procfile_path).include?("RSC_BUNDLE_ONLY")
          say "ℹ️  RSC bundle watcher already in Procfile.dev, skipping", :yellow
          return
        end

        say "📝 Adding RSC bundle watcher to Procfile.dev...", :yellow

        rsc_watcher_line = <<~PROCFILE

          # React on Rails Pro - RSC bundle watcher
          rsc-bundle: RSC_BUNDLE_ONLY=true bin/shakapacker-watch --watch
        PROCFILE

        append_to_file("Procfile.dev", rsc_watcher_line)

        say "✅ Added RSC bundle watcher to Procfile.dev", :green
      end

      def create_hello_server_component
        hello_server_dir = "app/javascript/src/HelloServer"
        ror_components_dir = "#{hello_server_dir}/ror_components"
        components_dir = "#{hello_server_dir}/components"
        ext = component_extension(options)

        # Check if HelloServer already exists (check both jsx and tsx)
        if File.exist?(File.join(destination_root, "#{ror_components_dir}/HelloServer.jsx")) ||
           File.exist?(File.join(destination_root, "#{ror_components_dir}/HelloServer.tsx"))
          say "ℹ️  HelloServer component already exists, skipping", :yellow
          return
        end

        say "📝 Creating HelloServer component...", :yellow

        # Create directories
        empty_directory(ror_components_dir)
        empty_directory(components_dir)

        # Copy component files (uses jsx or tsx based on --typescript flag)
        copy_file("templates/rsc/base/app/javascript/src/HelloServer/ror_components/HelloServer.#{ext}",
                  "#{ror_components_dir}/HelloServer.#{ext}")
        copy_file("templates/rsc/base/app/javascript/src/HelloServer/components/HelloServer.#{ext}",
                  "#{components_dir}/HelloServer.#{ext}")
        copy_file("templates/rsc/base/app/javascript/src/HelloServer/components/LikeButton.#{ext}",
                  "#{components_dir}/LikeButton.#{ext}")

        say "✅ Created HelloServer component", :green
      end

      def create_hello_server_controller
        controller_path = "app/controllers/hello_server_controller.rb"

        if File.exist?(File.join(destination_root, controller_path))
          say "ℹ️  HelloServerController already exists, skipping", :yellow
          return
        end

        say "📝 Creating HelloServerController...", :yellow

        layout_name = resolve_hello_server_layout_name
        template("templates/rsc/base/app/controllers/hello_server_controller.rb.tt",
                 controller_path,
                 layout_name: layout_name)

        say "✅ Created #{controller_path}", :green
      end

      def create_hello_server_view
        view_path = "app/views/hello_server/index.html.erb"

        if File.exist?(File.join(destination_root, view_path))
          say "ℹ️  HelloServer view already exists, skipping", :yellow
          return
        end

        say "📝 Creating HelloServer view...", :yellow

        # Create views directory if needed
        empty_directory("app/views/hello_server")

        template("templates/rsc/base/app/views/hello_server/index.html.erb.tt",
                 view_path,
                 build_hello_server_view_config(
                   landing_page: new_app_landing_page_available?,
                   redux_demo: options[:redux]
                 ))

        say "✅ Created #{view_path}", :green
      end

      def add_rsc_routes
        routes_file = File.join(destination_root, "config/routes.rb")

        unless File.exist?(routes_file)
          GeneratorMessages.add_warning(<<~MSG.strip)
            ⚠️  config/routes.rb not found. Skipping RSC routes.

            You'll need to add the following routes manually:
              rsc_payload_route
              get 'hello_server', to: 'hello_server#index'
          MSG
          return
        end

        routes_content = File.read(routes_file)

        if routes_content.include?("rsc_payload_route")
          say "ℹ️  RSC routes already exist, skipping", :yellow
          return
        end

        say "📝 Adding RSC routes...", :yellow

        # Add rsc_payload_route (required for RSC payload requests)
        route "rsc_payload_route"

        # Add HelloServer route (RSC counterpart to hello_world)
        route "get 'hello_server', to: 'hello_server#index'"

        say "✅ Added RSC routes to config/routes.rb", :green
      end

      # Update webpack configs to enable RSC support.
      # This is needed for standalone RSC upgrades where the base install
      # created webpack configs without RSC settings enabled.
      #
      # Updates:
      # - ServerClientOrBoth.js: RSC imports, rscConfig, RSC_BUNDLE_ONLY handling
      # - serverWebpackConfig.js: RSCWebpackPlugin import, rscBundle param, plugin
      # - clientWebpackConfig.js: RSCWebpackPlugin import, plugin
      def update_webpack_configs_for_rsc
        say "📝 Updating webpack configs for RSC...", :yellow

        update_server_client_or_both_for_rsc
        update_server_webpack_config_for_rsc
        update_client_webpack_config_for_rsc

        verify_rsc_webpack_transforms
        say "✅ Updated webpack configs for RSC", :green
      end

      def update_server_client_or_both_for_rsc
        config_path = resolve_server_client_or_both_path
        return unless config_path

        content = File.read(File.join(destination_root, config_path))

        # Skip if RSC is already configured
        return if content.include?("rscWebpackConfig")

        # Add RSC import after serverWebpackConfig import
        gsub_file(
          config_path,
          %r{(const (?:\{ default: serverWebpackConfig \}|serverWebpackConfig) = require\('\./serverWebpackConfig'\);)},
          "\\1\nconst rscWebpackConfig = require('./rscWebpackConfig');"
        )

        # Add rscConfig variable after serverConfig (with blank line separator)
        gsub_file(
          config_path,
          /^(\s*const serverConfig = serverWebpackConfig\(\);)$/,
          "\\1\n\n  const rscConfig = rscWebpackConfig();"
        )

        # Update envSpecific call to include rscConfig
        gsub_file(
          config_path,
          /envSpecific\(clientConfig, serverConfig\);/,
          "envSpecific(clientConfig, serverConfig, rscConfig);"
        )

        # Add RSC_BUNDLE_ONLY handling before the else block
        rsc_bundle_handling = <<~JS.chomp
          } else if (process.env.RSC_BUNDLE_ONLY) {
              // eslint-disable-next-line no-console
              console.log('[React on Rails] Creating only the RSC bundle.');
              result = rscConfig;
        JS
        gsub_file(
          config_path,
          %r{\n(\s*\} else \{\s*\n\s*// default is the standard client and server build)},
          "\n  #{rsc_bundle_handling}\n\\1"
        )

        # Update default multi-bundle output to include RSC
        gsub_file(
          config_path,
          /console\.log\('\[React on Rails\] Creating both client and server bundles\.'\);/,
          "console.log('[React on Rails] Creating client, server, and RSC bundles.');"
        )
        gsub_file(
          config_path,
          /result = \[clientConfig, serverConfig\];/,
          "result = [clientConfig, serverConfig, rscConfig];"
        )
      end

      def update_server_webpack_config_for_rsc
        config_path = destination_config_path("config/webpack/serverWebpackConfig.js")
        full_path = File.join(destination_root, config_path)

        return unless File.exist?(full_path)

        content = File.read(full_path)

        if content.include?("RSCWebpackPlugin")
          update_existing_rsc_webpack_config(config_path, content, is_server: true)
          return
        end

        # Add RSCWebpackPlugin import after bundler require
        return unless rsc_client_references_setup_anchor_available?(config_path, content, is_server: true)

        existing_imports_content = content_through_rsc_setup_anchor(content, is_server: true)
        return if rsc_setup_blocked_by_later_imports?(config_path, content, existing_imports_content, is_server: true)

        inject_rsc_server_imports(config_path, content, existing_imports_content)
        return unless rsc_client_references_setup_ready?(config_path)

        # Add rscBundle parameter to configureServer function
        gsub_file(
          config_path,
          /^const configureServer = \(\) => \{/,
          "// rscBundle parameter: when true, skips RSCWebpackPlugin (RSC bundle doesn't need it)\n" \
          "const configureServer = (rscBundle = false) => {"
        )

        # Add RSCWebpackPlugin to plugins before LimitChunkCountPlugin (matches template ordering)
        rsc_plugin_code = "// Add RSC plugin for server bundle (handles client component references)\n  " \
                          "// Skip for RSC bundle - it doesn't need RSCWebpackPlugin\n  " \
                          "if (!rscBundle) {\n    " \
                          "serverWebpackConfig.plugins.push(\n      " \
                          "new RSCWebpackPlugin({ isServer: true, clientReferences: rscClientReferences }),\n    " \
                          ");\n  " \
                          "}"
        gsub_file(
          config_path,
          /(serverWebpackConfig\.plugins\.unshift\(new bundler\.optimize\.LimitChunkCountPlugin.*\);)/,
          "#{rsc_plugin_code}\n  \\1"
        )
      end

      def update_client_webpack_config_for_rsc
        config_path = destination_config_path("config/webpack/clientWebpackConfig.js")
        full_path = File.join(destination_root, config_path)

        return unless File.exist?(full_path)

        content = File.read(full_path)

        if content.include?("RSCWebpackPlugin")
          update_existing_rsc_webpack_config(config_path, content, is_server: false)
          return
        end

        # Add RSCWebpackPlugin import after commonWebpackConfig import
        return unless rsc_client_references_setup_anchor_available?(config_path, content, is_server: false)

        existing_imports_content = content_through_rsc_setup_anchor(content, is_server: false)
        if rsc_setup_blocked_by_later_imports?(
          config_path, content, existing_imports_content, is_server: false
        )
          return
        end

        inject_rsc_client_imports(config_path, content, existing_imports_content)
        return unless rsc_client_references_setup_ready?(config_path)

        # Add RSCWebpackPlugin to client config before return statement
        rsc_plugin_code = "  // Add React Server Components plugin for client bundle\n  " \
                          "clientConfig.plugins.push(\n    " \
                          "new RSCWebpackPlugin({ isServer: false, clientReferences: rscClientReferences }),\n  " \
                          ");"
        gsub_file(
          config_path,
          /^( *return clientConfig;)$/,
          "#{rsc_plugin_code}\n\n\\1"
        )
      end

      def verify_rsc_webpack_transforms
        missing = []
        missing.concat(check_rsc_server_config)
        missing.concat(check_rsc_client_config)
        missing.concat(check_rsc_scob_config)
        return if missing.empty?

        GeneratorMessages.add_warning(<<~MSG.strip)
          ⚠️  Some RSC webpack transforms may not have applied correctly.

          Missing expected patterns:
          #{missing.map { |m| "  - #{m}" }.join("\n")}

          This can happen if your webpack config has been customized.
          Please verify your webpack configs manually.
        MSG
      end

      def check_rsc_server_config
        path = File.join(destination_root, destination_config_path("config/webpack/serverWebpackConfig.js"))
        return [] unless File.exist?(path)

        content = File.read(path)
        missing = []
        if content.include?("RSCWebpackPlugin")
          unless rsc_plugin_client_references_configured?(content, is_server: true)
            missing << "generated scoped clientReferences in serverWebpackConfig.js"
          end
        else
          missing << "RSCWebpackPlugin in serverWebpackConfig.js"
        end
        missing << "rscBundle parameter in serverWebpackConfig.js" unless content.include?("rscBundle")
        missing
      end

      def check_rsc_client_config
        path = File.join(destination_root, destination_config_path("config/webpack/clientWebpackConfig.js"))
        return [] unless File.exist?(path)

        content = File.read(path)
        missing = []
        if content.include?("RSCWebpackPlugin")
          unless rsc_plugin_client_references_configured?(content, is_server: false)
            missing << "generated scoped clientReferences in clientWebpackConfig.js"
          end
        else
          missing << "RSCWebpackPlugin in clientWebpackConfig.js"
        end
        missing
      end

      def check_rsc_scob_config
        scob_path = resolve_server_client_or_both_path
        return [] unless scob_path

        content = File.read(File.join(destination_root, scob_path))
        content.include?("rscWebpackConfig") ? [] : ["rscWebpackConfig in ServerClientOrBoth.js"]
      end

      def rsc_client_references_js
        <<~'JS'.chomp
          const rscClientReferences = {
            directory: resolve(config.source_path),
            recursive: true,
            include: /\.(js|ts|jsx|tsx)$/,
          };
        JS
      end

      def inject_rsc_client_imports(config_path, content, existing_imports_content)
        replace_rsc_client_references_setup_anchor(config_path, content, is_server: false) do |anchor|
          [
            anchor,
            shakapacker_config_import_statement(existing_imports_content),
            path_resolve_import_statement(existing_imports_content),
            "const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');",
            "",
            rsc_client_references_js
          ].compact.join("\n")
        end
      end

      def inject_rsc_server_imports(config_path, content, existing_imports_content)
        replace_rsc_client_references_setup_anchor(config_path, content, is_server: true) do |anchor|
          [
            anchor,
            path_resolve_import_statement(existing_imports_content),
            "const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');",
            "",
            rsc_client_references_js
          ].compact.join("\n")
        end
      end

      def update_existing_rsc_webpack_config(config_path, content, is_server:)
        return unless rsc_plugin_sections_safe_to_rewrite?(config_path, content, is_server: is_server)
        return if rsc_plugin_uses_scoped_client_references?(content, is_server: is_server)
        return unless rewritable_rsc_plugin?(config_path, content, is_server: is_server)
        return unless ensure_rsc_client_references_setup(config_path, content, is_server: is_server)

        rewrite_rsc_plugin_client_references(config_path, is_server: is_server) ||
          warn_missing_rsc_plugin_target(config_path, is_server: is_server)
      end

      # Detects RSCWebpackPlugin option blocks that the lightweight JS scanner could not parse
      # cleanly (most often a regex literal with an unmatched `{` / `}` that walks the depth
      # counter past the real closing brace). When found, we warn and refuse to rewrite anything
      # in the file so a sibling rewrite cannot accidentally splice into a wrong location.
      def rsc_plugin_sections_safe_to_rewrite?(config_path, content, is_server:)
        unparseable = rsc_plugin_option_sections_partition(content, is_server: is_server).fetch(:unparseable)
        return true if unparseable.zero?

        warn_unparseable_rsc_plugin_sections(config_path, unparseable)
        false
      end

      def rewritable_rsc_plugin?(config_path, content, is_server:)
        # Mixed same-target plugins are still rewritable: the later rewrite only updates plugins
        # missing clientReferences and leaves sibling custom clientReferences untouched.
        return true if rsc_plugin_without_client_references?(content, is_server: is_server)

        if rsc_plugin_defines_client_references?(content, is_server: is_server)
          GeneratorMessages.add_warning(
            "Skipped scoped clientReferences migration for #{config_path} because all matching " \
            "RSCWebpackPlugin instances already define clientReferences (some may already be " \
            "correctly scoped to rscClientReferences). Please verify manually."
          )
          return false
        end

        warn_missing_rsc_plugin_target(config_path, is_server: is_server)
        false
      end

      def warn_unparseable_rsc_plugin_sections(config_path, count)
        GeneratorMessages.add_warning(
          "Skipped scoped clientReferences migration for #{config_path}: #{count} RSCWebpackPlugin " \
          "options block(s) contain characters this lightweight scanner cannot parse safely " \
          "(most often a regex literal with an unmatched `{` or `}`, e.g. `/\\{/` or `/[{]/`). " \
          "Please add `clientReferences: rscClientReferences` manually to any RSCWebpackPlugin " \
          "that is missing it."
        )
      end

      def ensure_rsc_client_references_setup(config_path, content, is_server:)
        return true if scoped_rsc_client_references_defined?(content)

        if rsc_client_references_defined?(content)
          warn_unscoped_rsc_client_references_helper(config_path)
          return false
        end

        unless rsc_client_references_setup_anchor?(content, is_server: is_server)
          warn_missing_rsc_client_references_anchor(config_path)
          return false
        end

        existing_imports_content = content_through_rsc_setup_anchor(content, is_server: is_server)
        return false if rsc_setup_blocked_by_later_imports?(config_path, content, existing_imports_content,
                                                            is_server: is_server)

        add_rsc_client_references_setup(config_path, content, existing_imports_content, is_server: is_server)
        rsc_client_references_setup_ready?(config_path)
      end

      def rsc_plugin_uses_scoped_client_references?(content, is_server:)
        sections = rsc_plugin_option_sections(content, is_server: is_server)
        return false if sections.empty?
        return false unless scoped_rsc_client_references_defined?(content)

        sections.all? do |section|
          rsc_plugin_body_has_top_level_scoped_client_references?(section.fetch(:body))
        end
      end

      def rsc_plugin_client_references_configured?(content, is_server:)
        sections = rsc_plugin_option_sections(content, is_server: is_server)
        # No parseable `isServer: <bool>` section means this file's plugin call sits outside
        # what the generator's scanner can match (e.g. options are computed at runtime, or the
        # plugin is invoked without an options object). Verification callers intentionally
        # under-report here: warning about "missing scoped clientReferences" when there's no
        # section to inspect would only surface noise for dynamic invocations like
        # `RSCWebpackPlugin(buildOptions())`, where the user has nothing actionable to do.
        return true if sections.empty?

        sections.all? do |section|
          body = section.fetch(:body)
          if rsc_plugin_body_has_top_level_scoped_client_references?(body)
            scoped_rsc_client_references_defined?(content)
          else
            rsc_plugin_body_has_top_level_key?(body, "clientReferences")
          end
        end
      end

      def rsc_plugin_defines_client_references?(content, is_server:)
        rsc_plugin_option_sections(content, is_server: is_server).any? do |section|
          rsc_plugin_body_has_top_level_key?(section.fetch(:body), "clientReferences")
        end
      end

      def rsc_plugin_without_client_references?(content, is_server:)
        rsc_plugin_option_sections(content, is_server: is_server).any? do |section|
          !rsc_plugin_body_has_top_level_key?(section.fetch(:body), "clientReferences")
        end
      end

      # Strips JavaScript line and block comments while preserving string-literal contents,
      # so `clientReferences:` / `isServer:` substrings inside strings are not mis-detected.
      # Shares the `advance_js_scan_state` family used by `js_top_level_position?` and
      # `matching_js_closing_brace` so all JS-aware passes follow the same comment/string rules.
      # Regex literals (e.g. `/a{2}/`) are still outside this scanner's supported surface
      # because brace quantifiers can confuse `matching_js_closing_brace`'s depth counter.
      def rsc_plugin_options_without_comments(options)
        result = String.new(capacity: options.length)
        state = nil
        escaped = false
        index = 0

        while index < options.length
          char = options[index]
          next_char = options[index + 1]
          previous_state = state
          state, escaped, index = advance_js_scan_state(state, escaped, char, next_char, index)

          # Emit when (a) we're outside comments and strings and not just entering one, or
          # (b) we're inside or exiting a string (preserves the opening/closing quote and the
          # string contents), or (c) we're closing a line comment so the trailing `\n` survives
          # for line-anchored regex matching downstream (e.g. `^\s*isServer`).
          emit_char = (previous_state.nil? && !JS_COMMENT_STATES.include?(state)) ||
                      JS_STRING_DELIMITERS.include?(previous_state) ||
                      (previous_state == :line_comment && char == "\n")
          result << char if emit_char

          index += 1
        end

        result
      end

      # NOTE: internally rescans from index 0 for each `new RSCWebpackPlugin(` hit, so this is
      # O(n × m) in content size × plugin count. Acceptable for small webpack configs; carry
      # scanner state forward before adopting this pattern for larger shared inputs.
      def rsc_plugin_option_sections(content, is_server:)
        rsc_plugin_option_sections_partition(content, is_server: is_server).fetch(:safe)
      end

      # Returns the matching plugin sections plus a count of `RSCWebpackPlugin(` invocations
      # whose options block could not be parsed cleanly. An invocation is treated as
      # unparseable when the depth scanner cannot find a matching `}` (over-count caused by an
      # unmatched `{` in a regex literal) or when the `}` it finds is not followed by the `)`
      # that would close the `new RSCWebpackPlugin(...)` call (under-count caused by an
      # unmatched `}` in a regex literal). Both cases mean a rewrite based on this section
      # would corrupt the file, so callers must surface a warning instead of silently skipping.
      def rsc_plugin_option_sections_partition(content, is_server:)
        safe = []
        unparseable = 0
        search_from = 0
        marker = "new RSCWebpackPlugin("

        while (call_start = content.index(marker, search_from))
          unless js_code_position?(content, call_start)
            search_from = call_start + marker.length
            next
          end

          options_start = first_significant_js_index(content, call_start + marker.length)
          unless options_start && content[options_start] == "{"
            search_from = call_start + marker.length
            next
          end

          options_end = matching_js_closing_brace(content, options_start)
          unless options_end
            unparseable += 1
            search_from = options_start + 1
            next
          end

          unless rsc_plugin_options_followed_by_close_paren?(content, options_end)
            unparseable += 1
            search_from = options_end + 1
            next
          end

          body = content[(options_start + 1)...options_end]
          if rsc_plugin_is_server_match?(body, is_server: is_server)
            safe << { body: body, body_start: options_start + 1, body_end: options_end }
          end
          search_from = options_end + 1
        end

        { safe: safe, unparseable: unparseable }
      end

      # Walks forward from the assumed closing `}` of an options object, skipping whitespace
      # and JS comments, and confirms the next significant character is `)`. Used to detect
      # when `matching_js_closing_brace` was confused by a regex literal and returned an
      # earlier `}` than the real options-object close.
      #
      # String literals between `}` and `)` are not handled because no valid JS places one
      # there in `new RSCWebpackPlugin({...})` — a leading string-delimiter character would
      # simply be returned as a non-`)` and the section would be marked unparseable, which is
      # the safe outcome.
      def rsc_plugin_options_followed_by_close_paren?(content, options_end)
        state = nil
        escaped = false
        index = options_end + 1
        # Tolerate one trailing comma between the options object and `)` so configs formatted
        # with Prettier's `trailingComma: "all"` (`new RSCWebpackPlugin({...},)`) aren't flagged
        # as unparseable. A second comma still bails — that would be invalid JS.
        comma_seen = false

        while index < content.length
          char = content[index]
          next_char = content[index + 1]
          prev_state = state
          state, escaped, index = advance_js_scan_state(state, escaped, char, next_char, index)
          # Exiting a block comment leaves `char` as `*` and `index` pointing at the closing
          # `/`; advance past it so the next iteration evaluates the first character after `*/`.
          if state || prev_state == :block_comment
            index += 1
            next
          end

          unless char.match?(/\s/)
            return true if char == ")"
            return false if comma_seen || char != ","

            comma_seen = true
          end

          index += 1
        end

        false
      end

      # Skips both whitespace and JS line/block comments so callers see the first character
      # that actually participates in the syntax. Without comment skipping, configurations
      # like `new RSCWebpackPlugin( /* opts */ {` would land on `/` and be rejected as
      # "no plugin options" even though the options object is present.
      def first_significant_js_index(content, start_index)
        index = start_index
        state = nil
        escaped = false

        while index < content.length
          char = content[index]
          next_char = content[index + 1]
          prev_state = state
          state, escaped, index = advance_js_scan_state(state, escaped, char, next_char, index)
          # Exiting a block comment leaves `char` as `*` and `index` pointing at the closing
          # `/`; advance past it so the next iteration evaluates the first character after `*/`.
          if state || prev_state == :block_comment
            index += 1
            next
          end

          return index unless char.match?(/\s/)

          index += 1
        end

        nil
      end

      # Expects `content[open_index] == "{"`; callers pass the options-object opening brace.
      # This lightweight scanner treats template literals as opaque strings (backtick to backtick).
      # Simple `${...}` expressions are handled correctly: while in the backtick state every
      # character — including `{` and `}` inside the expression — is consumed as string content
      # and never reaches the depth counter. The real unsupported case is *nested* template
      # literals (e.g. `` `outer ${`inner`}` ``) where the inner backtick falsely closes the outer
      # string state, exposing later braces to the depth counter. Callers detect that via
      # `rsc_plugin_options_followed_by_close_paren?` and mark the section unparseable rather
      # than producing a corrupt rewrite. Regex literals are outside this scanner's supported
      # surface for the same reason.
      def matching_js_closing_brace(content, open_index)
        depth = 0
        index = open_index
        state = nil
        escaped = false

        while index < content.length
          char = content[index]
          # Nil at EOF is safe because downstream comparisons treat it as a non-match.
          next_char = content[index + 1]

          state, escaped, index = advance_js_scan_state(state, escaped, char, next_char, index)
          if state
            index += 1
            next
          end

          # `block_comment_exit_guard`: relies on `*` matching neither `{` nor `}`, so the
          # `*` returned at a `*/` exit is harmless here. If any future check below adds a
          # branch that could fire on `*` (or `)`, `/`, etc.), guard it with
          # `prev_state == :block_comment` per the contract on `advance_js_scan_state`.
          depth += 1 if char == "{"
          if char == "}"
            depth -= 1
            return index if depth.zero?
          end
          index += 1
        end

        nil
      end

      # Return index is the last consumed character. Line comments leave the newline
      # for the caller's normal index increment; block comments consume the closing slash.
      #
      # IMPORTANT CALLER CONTRACT — block-comment exit:
      # When this returns from a `*/` exit, `state` is cleared, but `char` is still the `*` and
      # the returned `index` points at the closing `/` (so the caller's trailing `index += 1`
      # lands on the first char after `*/`). Any caller whose post-call branch inspects `char`
      # as a "significant character" (e.g. `==` checks against `*`, `/`, `)`, `{`, `}`) MUST
      # explicitly guard on `prev_state == :block_comment` before that branch — otherwise the
      # `*` from the comment terminator is misread as code. Callers that only update accumulator
      # state (depth counters, string/comment booleans) are inherently safe because `*` doesn't
      # affect those. Searchable invariant name: `block_comment_exit_guard`.
      def advance_js_scan_state(state, escaped, char, next_char, index)
        return [char == "\n" ? nil : :line_comment, escaped, index] if state == :line_comment
        return advance_js_block_comment_state(escaped, char, next_char, index) if state == :block_comment
        return advance_js_string_state(state, escaped, char, index) if JS_STRING_DELIMITERS.include?(state)

        advance_js_default_scan_state(escaped, char, next_char, index)
      end

      def advance_js_block_comment_state(escaped, char, next_char, index)
        return [nil, escaped, index + 1] if char == "*" && next_char == "/"

        [:block_comment, escaped, index]
      end

      def advance_js_string_state(state, escaped, char, index)
        return [state, false, index] if escaped
        return [state, true, index] if char == "\\"
        # Explicit `false` (rather than passing `escaped` through) so a caller starting mid-parse
        # in a string state with a stale `escaped = true` cannot silently suppress the closing
        # quote and leave the scanner stuck in string state.
        return [nil, false, index] if char == state

        [state, escaped, index]
      end

      def advance_js_default_scan_state(escaped, char, next_char, index)
        return [:line_comment, escaped, index + 1] if char == "/" && next_char == "/"
        return [:block_comment, escaped, index + 1] if char == "/" && next_char == "*"
        return [char, escaped, index] if JS_STRING_DELIMITERS.include?(char)

        [nil, escaped, index]
      end

      def js_code_position?(content, target_index)
        state = nil
        escaped = false
        index = 0

        while index < target_index
          char = content[index]
          next_char = content[index + 1]
          state, escaped, index = advance_js_scan_state(state, escaped, char, next_char, index)
          index += 1
        end

        state.nil?
      end

      def js_top_level_position?(content, target_index)
        state = nil
        escaped = false
        depth = 0
        index = 0

        while index < target_index
          char = content[index]
          next_char = content[index + 1]
          state, escaped, index = advance_js_scan_state(state, escaped, char, next_char, index)
          if state
            index += 1
            next
          end

          depth += 1 if char == "{"
          depth -= 1 if char == "}" && depth.positive?
          index += 1
        end

        state.nil? && depth.zero?
      end

      # Depth-aware: a nested `metadata: { isServer: true }` inside another option's value
      # must NOT route the section into the `is_server: true` partition bucket — otherwise
      # the rewrite would correctly bail (the splice helper is also depth-aware) but
      # `warn_missing_rsc_plugin_target` would still fire and the user sees a misleading
      # "no plugin options with isServer: true could be rewritten" warning for a config that
      # is actually fine. Mirrors `rsc_plugin_body_has_top_level_key?` so partitioning and
      # splicing agree on what counts as a top-level `isServer:` pair. Comment/string skipping
      # is handled by `js_top_level_position?` via the shared `advance_js_scan_state`.
      def rsc_plugin_is_server_match?(body, is_server:)
        pattern = /\bisServer\s*:\s*#{Regexp.escape(is_server.to_s)}\b/
        search_from = 0
        while (match = pattern.match(body, search_from))
          return true if js_top_level_position?(body, match.begin(0))

          search_from = match.end(0)
        end
        false
      end

      def rewrite_rsc_plugin_client_references(config_path, is_server:)
        full_path = File.join(destination_root, config_path)
        # Re-read because ensure_rsc_client_references_setup may have just inserted the helper,
        # making the caller's in-memory body_start/body_end offsets stale.
        content = File.read(full_path)
        rewrites = rsc_plugin_option_sections(content, is_server: is_server).filter_map do |candidate|
          body = candidate.fetch(:body)
          # Depth-aware check: a nested `clientReferences:` (e.g. inside a sibling object
          # literal) must not be mistaken for a configured top-level option, or we'd skip
          # the migration and leave the real plugin unscoped.
          next if rsc_plugin_body_has_top_level_key?(body, "clientReferences")

          rewritten_body = add_client_references_to_rsc_plugin_body(body, is_server: is_server)
          next if rewritten_body == body

          [candidate, rewritten_body]
        end

        # The sole caller (`update_existing_rsc_webpack_config`) translates this `false` into
        # a `warn_missing_rsc_plugin_target` warning, so silently returning here is intentional.
        return false if rewrites.empty?

        # Reverse order so earlier offsets stay valid as later sections are spliced.
        rewrites.reverse_each do |section, rewritten_body|
          content[section.fetch(:body_start)...section.fetch(:body_end)] = rewritten_body
        end
        if options[:pretend]
          say_status(:pretend, "Would rewrite #{config_path}", :yellow)
        else
          # Direct write is intentional: multi-point rewrites cannot be expressed as one
          # gsub_file call, and pretend mode is already handled above.
          File.write(full_path, content)
          say_status(:rewrite, config_path, :green)
        end
        true
      end

      # Multi-line option objects get the new key on its own line just before the closing brace,
      # with indentation matching the last existing key, so the result reads cleanly without a
      # formatter pass. Single-line option objects keep the same-line splice immediately after
      # `isServer:` because that's the only readable place for a one-line object literal.
      def add_client_references_to_rsc_plugin_body(body, is_server:)
        pattern = /\bisServer\s*:\s*#{Regexp.escape(is_server.to_s)}\b/
        search_from = 0

        while (matched_is_server = pattern.match(body, search_from))
          # Require depth zero so a nested `isServer:` inside a sibling object literal
          # doesn't cause the splice to land inside the wrong object — `body` is the
          # content between the plugin options braces, so depth 0 == top-level options.
          if js_top_level_position?(body, matched_is_server.begin(0))
            return splice_client_references_into_rsc_plugin_body(body, matched_is_server)
          end

          search_from = matched_is_server.end(0)
        end

        body
      end

      # Walks every `<key>:` match in the plugin options body and returns true when at
      # least one sits at the top level of the options object (depth 0 from the body's
      # perspective, outside strings and comments). Used to gate "already configured"
      # checks so nested mentions don't cause false positives.
      def rsc_plugin_body_has_top_level_key?(body, key)
        pattern = /\b#{Regexp.escape(key)}\s*:/
        search_from = 0

        while (match = pattern.match(body, search_from))
          return true if js_top_level_position?(body, match.begin(0))

          search_from = match.end(0)
        end

        false
      end

      # Top-level depth-aware match for the migrated `clientReferences: rscClientReferences`
      # pair. Mirrors `rsc_plugin_body_has_top_level_key?` so verification and gating share
      # the same comment-, string-, and brace-aware semantics as the rewrite path.
      def rsc_plugin_body_has_top_level_scoped_client_references?(body)
        pattern = /\bclientReferences\s*:\s*rscClientReferences\b/
        search_from = 0

        while (match = pattern.match(body, search_from))
          return true if js_top_level_position?(body, match.begin(0))

          search_from = match.end(0)
        end

        false
      end

      def splice_client_references_into_rsc_plugin_body(body, is_server_match)
        return splice_client_references_at_close_brace(body) if body.include?("\n")
        # Other options follow `isServer:` on the same line — append after the last option so
        # `clientReferences` lands at the end of the object, matching the multi-line path's
        # close-brace splice rather than landing mid-object.
        return splice_client_references_at_single_line_end(body) if trailing_options_after?(body, is_server_match)

        "#{body[0...is_server_match.end(0)]}, clientReferences: rscClientReferences" \
          "#{body[is_server_match.end(0)..]}"
      end

      def trailing_options_after?(body, is_server_match)
        rest = body[is_server_match.end(0)..] || ""
        # A bare trailing comma (`isServer: false,`) is structural, not another option, so
        # consider only non-whitespace beyond it as "trailing options".
        rest.sub(/\A\s*,/, "").match?(/\S/)
      end

      def splice_client_references_at_single_line_end(body)
        trailing = body[/\s*\z/]
        content = body[0...(body.length - trailing.length)]
        content_without_comments = rsc_plugin_options_without_comments(content).rstrip
        separator = content_without_comments.end_with?(",") ? " " : ", "
        "#{content}#{separator}clientReferences: rscClientReferences#{trailing}"
      end

      def splice_client_references_at_close_brace(body)
        trailing = body[/\s*\z/]
        content = body[0...(body.length - trailing.length)]

        last_line_start = (content.rindex("\n") || -1) + 1
        # `[ \t]+` (one-or-more) so the regex returns nil when the last line is unindented,
        # letting the `|| "  "` fallback actually fire. With `*` the regex would always match
        # the empty string and the fallback was unreachable dead code.
        indent = content[last_line_start..][/\A[ \t]+/] || "  "

        content_without_comments = rsc_plugin_options_without_comments(content).rstrip
        needs_comma = !content_without_comments.end_with?(",")
        prefix = build_splice_prefix(content, needs_comma: needs_comma)

        "#{prefix}\n#{indent}clientReferences: rscClientReferences,#{trailing}"
      end

      # Inserts the trailing comma before any final line/block comment so the rewritten file reads
      # cleanly to a human. Appending the comma to the raw `content` would tuck it inside a
      # trailing `// note` (yielding `isServer: false  // note,`) — syntactically valid because
      # the comment hides the comma from the parser, but visually broken in code review and
      # likely to confuse a linter.
      def build_splice_prefix(content, needs_comma:)
        return content unless needs_comma

        last_code_index = last_js_code_char_index(content)
        return "#{content}," unless last_code_index

        "#{content[0..last_code_index]},#{content[(last_code_index + 1)..]}"
      end

      # Returns the index of the last character in `content` that is part of executable code —
      # i.e. neither whitespace nor inside a JS line/block comment. Strings count as code so a
      # value ending in `"foo"` keeps the closing quote in scope. Uses the shared
      # `advance_js_scan_state` family so comment/string handling matches every other JS-aware
      # pass in this file.
      def last_js_code_char_index(content)
        state = nil
        escaped = false
        index = 0
        result = nil

        while index < content.length
          char = content[index]
          next_char = content[index + 1]
          prev_state = state
          # Capture the pre-advance position so `result` always points at `char`'s index,
          # not the post-advance value that `advance_js_scan_state` may bump for `//`/`/*`/`*/`
          # transitions. The comment-state guard below covers those transitions, but capturing
          # explicitly makes the invariant obvious without relying on that coupling.
          char_index = index
          state, escaped, index = advance_js_scan_state(state, escaped, char, next_char, index)

          in_comment_now = JS_COMMENT_STATES.include?(state)
          was_in_comment = JS_COMMENT_STATES.include?(prev_state)
          result = char_index if !in_comment_now && !was_in_comment && !char.match?(/\s/)

          index += 1
        end

        result
      end

      def rsc_client_references_setup_anchor?(content, is_server:)
        !!rsc_client_references_setup_anchor_match(content, is_server: is_server)
      end

      # Called from the existing-config migration path, which is only reached after the
      # generator has already confirmed `RSCWebpackPlugin` is imported in the file. That's why
      # this helper deliberately omits the `RSCWebpackPlugin` import that `inject_rsc_*_imports`
      # adds on the from-scratch path — adding it here would produce a duplicate import.
      def add_rsc_client_references_setup(config_path, content, existing_imports_content, is_server:)
        # Belt-and-suspenders: the only caller, `ensure_rsc_client_references_setup`, already
        # checks both `scoped_rsc_client_references_defined?` and `rsc_client_references_defined?`
        # before delegating here. The guards are kept so the helper is safe to call directly.
        return if scoped_rsc_client_references_defined?(content)
        return if rsc_client_references_defined?(content)

        replace_rsc_client_references_setup_anchor(config_path, content, is_server: is_server) do |anchor|
          [
            anchor,
            # On the server path `shakapacker_config_blocker_reason` has already blocked when
            # `config` is missing from `existing_imports_content`, so this call returns `nil`.
            # Kept (rather than skipped on `is_server`) so removing the upstream blocker does not
            # silently drop the import on the client path, where its absence is permitted.
            shakapacker_config_import_statement(existing_imports_content),
            path_resolve_import_statement(existing_imports_content),
            "",
            rsc_client_references_js
          ].compact.join("\n")
        end
      end

      def replace_rsc_client_references_setup_anchor(config_path, content, is_server:)
        anchor_match = rsc_client_references_setup_anchor_match(content, is_server: is_server)
        return unless anchor_match

        updated_content = content.dup
        updated_content[anchor_match.begin(0)...anchor_match.end(0)] = yield anchor_match[0]
        if options[:pretend]
          say_status(:pretend, "Would inject rscClientReferences into #{config_path}", :yellow)
        else
          File.write(File.join(destination_root, config_path), updated_content)
          say_status(:insert, config_path, :green)
        end
      end

      def shakapacker_config_import_statement(existing_imports_content)
        return if shakapacker_config_imported?(existing_imports_content)

        "const { config } = require('shakapacker');"
      end

      def path_resolve_import_statement(existing_imports_content)
        return if path_resolve_imported?(existing_imports_content)

        "const { resolve } = require('path');"
      end

      def rsc_client_references_setup_import_pattern(is_server:)
        if is_server
          # Matches the standard 3-line bundler ternary from the serverWebpackConfig template.
          # Rspack-only configs without the webpack fallback receive the manual-migration warning.
          Regexp.new(
            "(const bundler = config\\.assets_bundler.*\\r?\\n" \
            ".*require\\(['\"]@rspack/core['\"]\\).*\\r?\\n" \
            ".*: require\\(['\"]webpack['\"]\\);)"
          )
        else
          %r{(const commonWebpackConfig = require\(['"]\./commonWebpackConfig['"]\);)}
        end
      end

      def rsc_client_references_defined?(content)
        # Module-scope guard mirrors the other detection helpers (e.g. `path_resolve_imported?`,
        # `shakapacker_config_imported?`) so a function-scoped `const rscClientReferences` does
        # not fool `ensure_rsc_client_references_setup` into skipping the helper injection — that
        # would leave the plugin rewrite referencing an out-of-scope binding.
        # `let` and `var` are matched alongside `const` because a hand-written
        # `let rscClientReferences = {...}` at module scope would otherwise slip past this check
        # and cause the migration to emit a second `const rscClientReferences = {...}`, producing
        # an `Identifier 'rscClientReferences' has already been declared` SyntaxError at config load.
        pattern = /^[ \t]*(?:const|let|var)\s+rscClientReferences\b/
        content.to_enum(:scan, pattern).any? do
          js_top_level_position?(content, Regexp.last_match.begin(0))
        end
      end

      def scoped_rsc_client_references_defined?(content)
        # Locate the actual module-scope `const|let|var rscClientReferences = { ... }` site and
        # check the `directory:` key against the object literal body with comments stripped.
        # Running the regex against the raw file would treat a stale, commented-out
        # `// directory: resolve(config.source_path)` (e.g. left over from a prior failed
        # migration) as a real scoped declaration and silently short-circuit
        # `ensure_rsc_client_references_setup`, leaving the plugin unscoped without any warning.
        decl_pattern = /^[ \t]*(?:const|let|var)\s+rscClientReferences\s*=\s*\{/
        content.to_enum(:scan, decl_pattern).any? do
          match = Regexp.last_match
          next false unless js_top_level_position?(content, match.begin(0))

          open_brace = match.end(0) - 1
          close_brace = matching_js_closing_brace(content, open_brace)
          next false unless close_brace

          body = content[(open_brace + 1)...close_brace]
          rsc_plugin_options_without_comments(body)
            .match?(/\bdirectory\s*:\s*resolve\(\s*config\.source_path\s*\)/)
        end
      end

      # Inclusive slice — the anchor itself is part of the returned content because callers
      # (`rsc_setup_blocked_by_later_imports?`, `inject_rsc_*_imports`, the import-detection
      # helpers) check whether required imports appear up to and including the anchor line.
      # Anything past the anchor is considered "later" and disqualifies an otherwise-valid import.
      def content_through_rsc_setup_anchor(content, is_server:)
        anchor = rsc_client_references_setup_anchor_match(content, is_server: is_server)
        return "" unless anchor

        content[0...anchor.end(0)]
      end

      def rsc_client_references_setup_anchor_match(content, is_server:)
        pattern = rsc_client_references_setup_import_pattern(is_server: is_server)
        content.to_enum(:scan, pattern).each do
          match = Regexp.last_match
          return match if js_code_position?(content, match.begin(0))
        end
        nil
      end

      def rsc_setup_blocked_by_later_imports?(config_path, content, existing_imports_content, is_server:)
        reason = rsc_setup_blocker_reason(content, existing_imports_content, is_server: is_server)
        return false unless reason

        GeneratorMessages.add_warning(
          "Could not inject rscClientReferences into #{config_path}: #{reason}. " \
          "Please add clientReferences manually."
        )
        true
      end

      # Reports the first blocker that prevents the generator from injecting `rscClientReferences`.
      # Each branch returns a message specific enough that the user can act on it without re-deriving
      # the cause from a generic "imports unavailable" warning.
      def rsc_setup_blocker_reason(content, existing_imports_content, is_server:)
        path_resolve_blocker_reason(content, existing_imports_content) ||
          shakapacker_config_blocker_reason(content, existing_imports_content, is_server: is_server)
      end

      def path_resolve_blocker_reason(content, existing_imports_content)
        return nil if path_resolve_imported?(existing_imports_content)

        if top_level_resolve_binding?(content)
          "a top-level `resolve` binding already exists that would conflict with the injected " \
            "`const { resolve } = require('path')`"
        elsif path_resolve_imported?(content)
          "the `resolve` import from `path` appears after the expected anchor line — " \
            "move the import above it"
        end
      end

      # Intentional server/client asymmetry: when shakapacker's `config` is absent from the
      # file entirely (not misplaced, not aliased), the client branch falls through and returns
      # `nil` so the generator proceeds and adds the import alongside `rscClientReferences`. The
      # server branch always blocks because the server anchor (`config.assets_bundler === 'rspack'`)
      # itself requires `config` to be in scope, so an absent shakapacker import is always a user
      # configuration problem there.
      def shakapacker_config_blocker_reason(content, existing_imports_content, is_server:)
        return nil if shakapacker_config_imported?(existing_imports_content)

        shakapacker_anywhere = shakapacker_config_imported?(content)

        if shakapacker_anywhere
          if is_server
            "shakapacker's `config` is imported after the bundler ternary anchor — " \
              "move the import above it"
          else
            "shakapacker's `config` is imported after the `commonWebpackConfig` anchor — " \
              "move the import above it"
          end
        elsif top_level_config_binding?(content)
          "a top-level `config` binding already exists that would conflict with the injected " \
            "`const { config } = require('shakapacker')`"
        elsif is_server
          "shakapacker's `config` is not imported in this file — add " \
            "`const { config } = require('shakapacker');` before the bundler ternary"
        end
      end

      def shakapacker_config_imported?(content)
        return true if commonjs_named_imported?(content, "shakapacker", "config")

        top_level_dot_access_import?(content,
                                     /^[ \t]*(?:const|let|var)\s+config\s*=\s*require\(['"]shakapacker['"]\)\.config/)
      end

      def path_resolve_imported?(content)
        # Full-module imports (`const path = require('path')`) do not create the bare `resolve` binding
        # that rscClientReferences uses, so the generator may add a harmless named import alongside them.
        return true if commonjs_named_imported?(content, "path", "resolve")

        top_level_dot_access_import?(content,
                                     /^[ \t]*(?:const|let|var)\s+resolve\s*=\s*require\(['"]path['"]\)\.resolve/)
      end

      # Verifies that a regex match is at module-scope depth=0 to avoid false positives
      # from function-scoped `require` calls (which do not produce module-scope bindings).
      def top_level_dot_access_import?(content, pattern)
        content.to_enum(:scan, pattern).any? do
          js_top_level_position?(content, Regexp.last_match.begin(0))
        end
      end

      def top_level_resolve_binding?(content)
        pattern = /^[ \t]*(?:(?:const|let|var)\s+resolve\b|function\s+resolve\s*\()/

        content.to_enum(:scan, pattern).any? do
          js_top_level_position?(content, Regexp.last_match.begin(0))
        end
      end

      def top_level_config_binding?(content)
        pattern = /^[ \t]*(?:(?:const|let|var)\s+config\b|function\s+config\s*\()/

        content.to_enum(:scan, pattern).any? do
          js_top_level_position?(content, Regexp.last_match.begin(0))
        end
      end

      def rsc_client_references_setup_anchor_available?(config_path, content, is_server:)
        return true if rsc_client_references_setup_anchor?(content, is_server: is_server)

        warn_missing_rsc_client_references_anchor(config_path)
        false
      end

      def rsc_client_references_setup_ready?(config_path)
        return true if options[:pretend]
        return true if scoped_rsc_client_references_defined?(File.read(File.join(destination_root, config_path)))

        warn_rsc_client_references_injection_failed(config_path)
        false
      end

      def warn_missing_rsc_client_references_anchor(config_path)
        GeneratorMessages.add_warning(
          "Could not inject rscClientReferences into #{config_path}: expected webpack import anchor was not found " \
          "(the generator looks for the CommonJS `require`-style anchor that the ROR templates emit). " \
          "If your config uses ESM `import` syntax, the generator cannot migrate it automatically. " \
          "Please add clientReferences manually."
        )
      end

      def warn_rsc_client_references_injection_failed(config_path)
        GeneratorMessages.add_warning(
          "Could not inject rscClientReferences into #{config_path}: expected webpack import anchor was found, " \
          "but the generated scoped helper setup was not written. Please add clientReferences manually."
        )
      end

      def warn_unscoped_rsc_client_references_helper(config_path)
        GeneratorMessages.add_warning(
          "Skipped scoped clientReferences migration for #{config_path} because rscClientReferences already exists " \
          "but does not point to resolve(config.source_path). Please verify it manually."
        )
      end

      def warn_missing_rsc_plugin_target(config_path, is_server:)
        GeneratorMessages.add_warning(
          "Could not update RSCWebpackPlugin in #{config_path}: no plugin options with isServer: #{is_server} " \
          "could be rewritten. Please add clientReferences manually."
        )
      end

      def commonjs_named_imported?(content, package_name, binding_name)
        # `[^}]*` is intentionally newline-permissive (Ruby character classes match `\n`),
        # so multi-line destructuring like `const {\n  config,\n} = require('shakapacker')` matches.
        # `[^}]*` cannot match nested destructuring like
        # `const { config: { source_path } } = require('shakapacker')` because the inner `}`
        # terminates the character class early. That shape is outside this matcher's
        # supported surface for the same reason aliases and split-comma defaults are.
        pattern = /^[ \t]*(?:const|let|var)\s+\{([^}]*)\}\s*=\s*require\(['"]#{Regexp.escape(package_name)}['"]\);?/

        content.to_enum(:scan, pattern).any? do |captures|
          # Module-scope check guards against false positives when the same destructuring
          # appears inside a function body (which does not produce a module-scope binding).
          next false unless js_top_level_position?(content, Regexp.last_match.begin(0))

          bindings = captures.first

          bindings.split(",").any? do |binding|
            binding = binding.strip
            # Aliases (`config: alias`) do not provide the exact binding that rscClientReferences uses.
            # The `binding = fallback` form covers JavaScript destructuring defaults whose default
            # value does not contain a comma — `{ config = fn(a, b) }` would split on the comma
            # inside `fn(a, b)` and fall outside this matcher's supported surface, same as alias
            # renames. Inline comments inside the destructuring list
            # (`const { config /* primary */ } = require('shakapacker')`) are also unsupported:
            # they leave their text in the captured binding so the exact `config` match fails.
            # All of these shapes are vanishingly rare in real webpack configs.
            binding == binding_name || binding.start_with?("#{binding_name} =")
          end
        end
      end

      def resolve_hello_server_layout_name
        classification_by_layout = candidate_layout_names.to_h do |layout_name|
          [layout_name, classify_hello_server_layout(layout_name)]
        end

        reusable_layout_name = find_reusable_hello_server_layout_name(classification_by_layout)
        return reusable_layout_name if reusable_layout_name

        create_new_hello_server_layout(
          skipped_layout_paths: skipped_existing_layout_paths(classification_by_layout)
        )
      end

      def find_reusable_hello_server_layout_name(classification_by_layout)
        declared_layout_name = hello_world_controller_layout_name

        if reusable_layout_classification?(classification_by_layout[declared_layout_name])
          announce_reused_hello_server_layout(declared_layout_name, classification_by_layout[declared_layout_name])
          return declared_layout_name
        end

        preferred_layout_name = first_layout_name_with_classification(
          classification_by_layout,
          :canonical,
          excluding: declared_layout_name
        )
        return preferred_layout_name if preferred_layout_name

        first_layout_name_with_reusable_classification(
          classification_by_layout,
          excluding: declared_layout_name
        )
      end

      def first_layout_name_with_classification(classification_by_layout, expected_classification, excluding: nil)
        classification_by_layout.each do |layout_name, classification|
          next if layout_name == excluding
          next unless classification == expected_classification

          announce_reused_hello_server_layout(layout_name, classification)
          return layout_name
        end

        nil
      end

      def first_layout_name_with_reusable_classification(classification_by_layout, excluding: nil)
        classification_by_layout.each do |layout_name, classification|
          next if layout_name == excluding
          next unless reusable_layout_classification?(classification)

          announce_reused_hello_server_layout(layout_name, classification)
          return layout_name
        end

        nil
      end

      def announce_reused_hello_server_layout(layout_name, classification)
        message = +"ℹ️  Reusing existing #{layout_name} layout for HelloServerController"
        message << " (new generated layouts use empty pack tags by default)" if classification == :reusable
        say message, :yellow
      end

      def candidate_layout_names
        [
          hello_world_controller_layout_name,
          DEFAULT_LAYOUT_NAME,
          LEGACY_LAYOUT_NAME,
          *existing_rsc_layout_names
        ].compact.uniq
      end

      def hello_world_controller_layout_name
        return @hello_world_controller_layout_name if defined?(@hello_world_controller_layout_name)

        controller_path = File.join(destination_root, "app/controllers/hello_world_controller.rb")
        @hello_world_controller_layout_name = if File.exist?(controller_path)
                                                extract_declared_layout_name(File.read(controller_path))
                                              end
      end

      def extract_declared_layout_name(controller_content)
        match = controller_content.match(/^\s*layout(?:\s+|\s*\(\s*)(?:"([^"]+)"|'([^']+)')(?=\s*(?:\)|,|#|$))/)
        match&.captures&.compact&.first
      end

      def existing_rsc_layout_names
        Dir.glob(File.join(destination_root, "app/views/layouts/react_on_rails_rsc*.html.erb"))
           .map { |path| File.basename(path, ".html.erb") }
           .select { |layout_name| generated_rsc_layout_name?(layout_name) }
      end

      def generated_rsc_layout_name?(layout_name)
        layout_name.match?(RSC_GENERATED_LAYOUT_NAME_PATTERN)
      end

      def classify_hello_server_layout(layout_name)
        layout_path = layout_destination_path(layout_name)
        full_path = File.join(destination_root, layout_path)
        return :missing unless File.exist?(full_path)

        layout_content = File.read(full_path)
        return :missing_pack_tags unless layout_has_required_pack_tags?(layout_content)

        return :canonical if layout_uses_canonical_pack_tags?(layout_content)

        :reusable
      end

      def skipped_existing_layout_paths(classification_by_layout)
        classification_by_layout.filter_map do |layout_name, classification|
          layout_path = layout_destination_path(layout_name)
          full_path = File.join(destination_root, layout_path)

          next unless File.exist?(full_path)
          next if reusable_layout_classification?(classification)

          layout_path
        end
      end

      def layout_destination_path(layout_name)
        "app/views/layouts/#{layout_name}.html.erb"
      end

      def layout_has_required_pack_tags?(layout_content)
        pack_tag_present?(layout_content, "javascript_pack_tag") &&
          pack_tag_present?(layout_content, "stylesheet_pack_tag")
      end

      def layout_uses_canonical_pack_tags?(layout_content)
        pack_tag_without_names?(layout_content, "javascript_pack_tag") &&
          pack_tag_without_names?(layout_content, "stylesheet_pack_tag")
      end

      def reusable_layout_classification?(classification)
        %i[canonical reusable].include?(classification)
      end

      def pack_tag_present?(layout_content, helper_name)
        pack_tag_arguments(layout_content, helper_name).any?
      end

      def pack_tag_without_names?(layout_content, helper_name)
        arguments = pack_tag_arguments(layout_content, helper_name)
        arguments.any? && arguments.all? do |pack_tag_arguments|
          pack_tag_arguments_without_names?(pack_tag_arguments)
        end
      end

      def pack_tag_arguments(layout_content, helper_name)
        arguments_pattern = '\s*(?:\((?:(?!%>).)*?\)|(?:(?!%>).)*?)'
        pattern = /<%=\s*#{Regexp.escape(helper_name)}(?=\s|\(|%>)(?<arguments>#{arguments_pattern})?\s*%>/m

        arguments = []
        layout_content.scan(pattern) do
          arguments << Regexp.last_match[:arguments]
        end

        arguments
      end

      def pack_tag_arguments_without_names?(arguments)
        normalized_arguments = strip_wrapping_parentheses(arguments.to_s.strip)
        return true if normalized_arguments.empty?

        normalized_arguments.match?(/\A(?:\*\*[A-Za-z_]\w*|[a-z_]\w*\s*:.*)\z/m)
      end

      def strip_wrapping_parentheses(arguments)
        return arguments unless arguments.start_with?("(") && arguments.end_with?(")")

        arguments[1...-1].strip
      end

      def create_new_hello_server_layout(skipped_layout_paths: [])
        layout_name = next_available_hello_server_layout_name
        layout_path = layout_destination_path(layout_name)

        announce_skipped_layout_fallback(skipped_layout_paths, layout_path) if skipped_layout_paths.any?

        say "📝 Creating #{layout_path} for HelloServerController...", :yellow
        empty_directory("app/views/layouts")
        copy_file("templates/base/base/app/views/layouts/react_on_rails_default.html.erb", layout_path)
        say "✅ Created #{layout_path}", :green

        layout_name
      end

      def announce_skipped_layout_fallback(skipped_layout_paths, new_layout_path)
        skipped_paths = skipped_layout_paths.map { |path| "  - #{path}" }.join("\n")

        say <<~MSG, :yellow
          ℹ️  Found existing layout file(s) in your app that were not reused for HelloServerController:
          #{skipped_paths}

          Those file(s) do not include both `stylesheet_pack_tag` and `javascript_pack_tag`, so the generator
          will create #{new_layout_path} instead of overwriting them.
          New generated layouts use empty pack tags by default.
        MSG
      end

      def next_available_hello_server_layout_name
        default_layout_path = File.join(destination_root, layout_destination_path(DEFAULT_LAYOUT_NAME))
        return DEFAULT_LAYOUT_NAME unless File.exist?(default_layout_path)

        fallback_layout_path = File.join(destination_root, layout_destination_path(RSC_FALLBACK_LAYOUT_NAME))
        return RSC_FALLBACK_LAYOUT_NAME unless File.exist?(fallback_layout_path)

        (2..MAX_LAYOUT_NAME_ATTEMPTS).each do |suffix|
          layout_name = "#{RSC_FALLBACK_LAYOUT_NAME}_#{suffix}"
          return layout_name unless File.exist?(File.join(destination_root, layout_destination_path(layout_name)))
        end

        raise "Could not find an available RSC layout name after #{MAX_LAYOUT_NAME_ATTEMPTS} attempts."
      end
    end
  end
end

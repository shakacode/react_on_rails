# frozen_string_literal: true

require_relative "generator_messages"
require_relative "demo_page_config"
require_relative "rsc_setup/client_references"
require_relative "rsc_setup/layouts"

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
      include ClientReferences
      include Layouts

      DEFAULT_LAYOUT_NAME = "react_on_rails_default"
      LEGACY_LAYOUT_NAME = "hello_world"
      RSC_FALLBACK_LAYOUT_NAME = "react_on_rails_rsc"
      RSC_GENERATED_LAYOUT_NAME_PATTERN = /\Areact_on_rails_rsc(?:_(?:[2-9]|[1-9]\d+))?\z/
      MAX_LAYOUT_NAME_ATTEMPTS = 99

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
              #{manual_add_packages_command(['react@~19.0.4', 'react-dom@~19.0.4'])}
          MSG
        elsif patch < 4
          GeneratorMessages.add_warning(<<~MSG.strip)
            ⚠️  React #{react_version} is below the recommended minimum for RSC.

            Please upgrade to at least React 19.0.4:
              #{manual_add_packages_command(['react@19.0.4', 'react-dom@19.0.4'])}

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
        hello_server_dir = example_component_source_directory("HelloServer")
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
          warn_existing_hello_server_tailwind_layout(controller_path)
          say "ℹ️  HelloServerController already exists, skipping", :yellow
          return
        end

        say "📝 Creating HelloServerController...", :yellow

        layout_name = resolve_hello_server_layout_name
        template("templates/rsc/base/app/controllers/hello_server_controller.rb.tt",
                 controller_path,
                 layout_name:)

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
                   redux_demo: options[:redux],
                   source_path: example_component_source_path("HelloServer")
                 ))

        say "✅ Created #{view_path}", :green
      end

      def warn_existing_hello_server_tailwind_layout(controller_path)
        return unless use_tailwind?
        return if hello_server_controller_uses_tailwind_layout?(controller_path)

        GeneratorMessages.add_warning(<<~MSG.strip)
          ⚠️  HelloServerController already exists and may not use the Tailwind-aware React on Rails layout.

          Ensure #{controller_path} uses a layout that includes:
            <% prepend_javascript_pack_tag "#{tailwind_pack_name}" %>
            <%= stylesheet_pack_tag "#{tailwind_pack_name}", media: "all" %>
            <%= javascript_pack_tag %>
        MSG
      end

      def hello_server_controller_uses_tailwind_layout?(controller_path)
        controller_full_path = File.join(destination_root, controller_path)
        layout_name = extract_declared_layout_name(File.read(controller_full_path))
        layout_name ||= inherited_application_layout_name

        layout_file_links_tailwind_pack?(layout_name)
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
      # - serverWebpackConfig.js: RSC plugin import (RSCRspackPlugin/RSCWebpackPlugin), rscBundle param, plugin
      # - clientWebpackConfig.js: RSC plugin import (RSCRspackPlugin/RSCWebpackPlugin), plugin
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

        if rsc_plugin_invocation_in_js_code?(content)
          update_existing_rsc_webpack_config(config_path, content, is_server: true)
          return
        end

        # Add the RSC plugin import after bundler require
        return unless rsc_client_references_setup_anchor_available?(
          config_path,
          content,
          is_server: true,
          plugin_pending: true
        )

        existing_imports_content = content_through_rsc_setup_anchor(content, is_server: true)
        setup_status = prepare_rsc_plugin_imports(config_path, content, existing_imports_content, is_server: true)
        return if setup_status == :failed

        # Add rscBundle parameter to configureServer function
        gsub_file(
          config_path,
          /^const configureServer = \(\) => \{/,
          "// rscBundle parameter: when true, skips #{rsc_plugin_class_name} (RSC bundle doesn't need it)\n" \
          "const configureServer = (rscBundle = false) => {"
        )

        # Add the RSC plugin to plugins before LimitChunkCountPlugin (matches template ordering)
        client_references_option = setup_status == :scoped ? ", clientReferences: rscClientReferences" : ""
        rsc_plugin_code = "// Add RSC plugin for server bundle (handles client component references)\n  " \
                          "// Skip for RSC bundle - it doesn't need #{rsc_plugin_class_name}\n  " \
                          "if (!rscBundle) {\n    " \
                          "serverWebpackConfig.plugins.push(\n      " \
                          "new #{rsc_plugin_class_name}({ isServer: true#{client_references_option} }),\n    " \
                          ");\n  " \
                          "}"
        gsub_file(
          config_path,
          /(serverWebpackConfig\.plugins\.unshift\(new bundler\.optimize\.LimitChunkCountPlugin.*\);)/,
          "#{rsc_plugin_code}\n  \\1"
        )
        rollback_incomplete_new_rsc_plugin_setup(config_path, content, is_server: true)
      end

      def update_client_webpack_config_for_rsc
        config_path = destination_config_path("config/webpack/clientWebpackConfig.js")
        full_path = File.join(destination_root, config_path)

        return unless File.exist?(full_path)

        content = File.read(full_path)

        if rsc_plugin_invocation_in_js_code?(content)
          update_existing_rsc_webpack_config(config_path, content, is_server: false)
          return
        end

        # Add the RSC plugin import after commonWebpackConfig import
        return unless rsc_client_references_setup_anchor_available?(
          config_path,
          content,
          is_server: false,
          plugin_pending: true
        )

        existing_imports_content = content_through_rsc_setup_anchor(content, is_server: false)
        setup_status = prepare_rsc_plugin_imports(config_path, content, existing_imports_content, is_server: false)
        return if setup_status == :failed

        # Add the RSC plugin to client config before return statement
        client_references_option = setup_status == :scoped ? ", clientReferences: rscClientReferences" : ""
        rsc_plugin_code = "  // Add React Server Components plugin for client bundle\n  " \
                          "clientConfig.plugins.push(\n    " \
                          "new #{rsc_plugin_class_name}({ isServer: false#{client_references_option} }),\n  " \
                          ");"
        gsub_file(
          config_path,
          /^( *return clientConfig;)$/,
          "#{rsc_plugin_code}\n\n\\1"
        )
        rollback_incomplete_new_rsc_plugin_setup(config_path, content, is_server: false)
      end

      def rollback_incomplete_new_rsc_plugin_setup(config_path, original_content, is_server:)
        return if options[:pretend] || options[:skip]

        full_path = File.join(destination_root, config_path)
        current_content = File.read(full_path)
        return if new_rsc_plugin_setup_complete?(current_content, is_server:)
        return if current_content == original_content

        say_status(:revert, config_path, :yellow)
        File.write(full_path, original_content)
        warn_incomplete_new_rsc_plugin_setup(config_path, is_server:)
      end

      def new_rsc_plugin_setup_complete?(content, is_server:)
        return false unless rsc_plugin_invocation_in_js_code?(content)
        # Client path intentionally only requires the plugin invocation, not the scoped helper.
        # The `:unscoped` degraded path (taken when scoping is blocked) writes the plugin
        # without `rscClientReferences`, and this guard must not trigger the rollback in that
        # case. The server path keeps the stricter check below because the `rscBundle`
        # signature change is the marker of a complete server-side rewrite.
        return true unless is_server

        rsc_server_signature_in_js_code?(content)
      end

      # Returns true when the file contains a real `new RSCWebpackPlugin(` / `new RSCRspackPlugin(`
      # invocation in actual JS code — not inside a comment or string literal. Reuses
      # `RSC_PLUGIN_INVOCATION_REGEX` from the ClientReferences module (which matches both bundler
      # plugin names) so the routing check and the option-section partition match the same set of
      # invocations (including whitespace/newline variants).
      def rsc_plugin_invocation_in_js_code?(content)
        content
          .to_enum(:scan, RSC_PLUGIN_INVOCATION_REGEX)
          .any? { js_code_position?(content, Regexp.last_match.begin(0)) }
      end

      def rsc_server_signature_in_js_code?(content)
        content
          .to_enum(:scan, /configureServer\s*=\s*\(\s*rscBundle\s*=\s*false\s*\)/)
          .any? { js_code_position?(content, Regexp.last_match.begin(0)) }
      end

      def warn_incomplete_new_rsc_plugin_setup(config_path, is_server:)
        insertion_point = is_server ? "server bundler insertion points" : "client bundler return statement"
        GeneratorMessages.add_warning(
          "Could not finish adding #{rsc_plugin_class_name} to #{config_path}: expected #{insertion_point} " \
          "was not found. Reverted partial RSC setup; please add #{rsc_plugin_class_name} and " \
          "clientReferences manually."
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
        if content.include?(rsc_plugin_class_name)
          missing.concat(stale_inactive_rsc_plugin_messages(content, "serverWebpackConfig.js"))
          warn_non_object_literal_rsc_plugin_options_for_config(content)
          unless rsc_plugin_client_references_configured?(content, is_server: true)
            missing << "generated scoped clientReferences in serverWebpackConfig.js"
          end
        elsif inactive_rsc_plugin_symbol_in_js_code?(content)
          missing << "#{rsc_plugin_class_name} in serverWebpackConfig.js " \
                     "(found #{inactive_rsc_plugin_class_name} — wrong bundler plugin; replace it manually)"
        else
          missing << "#{rsc_plugin_class_name} in serverWebpackConfig.js"
        end
        missing << "rscBundle parameter in serverWebpackConfig.js" unless content.include?("rscBundle")
        missing
      end

      def check_rsc_client_config
        path = File.join(destination_root, destination_config_path("config/webpack/clientWebpackConfig.js"))
        return [] unless File.exist?(path)

        content = File.read(path)
        missing = []
        if content.include?(rsc_plugin_class_name)
          missing.concat(stale_inactive_rsc_plugin_messages(content, "clientWebpackConfig.js"))
          warn_non_object_literal_rsc_plugin_options_for_config(content)
          unless rsc_plugin_client_references_configured?(content, is_server: false)
            missing << "generated scoped clientReferences in clientWebpackConfig.js"
          end
        elsif inactive_rsc_plugin_symbol_in_js_code?(content)
          missing << "#{rsc_plugin_class_name} in clientWebpackConfig.js " \
                     "(found #{inactive_rsc_plugin_class_name} — wrong bundler plugin; replace it manually)"
        else
          missing << "#{rsc_plugin_class_name} in clientWebpackConfig.js"
        end
        missing
      end

      def check_rsc_scob_config
        scob_path = resolve_server_client_or_both_path
        return [] unless scob_path

        content = File.read(File.join(destination_root, scob_path))
        content.include?("rscWebpackConfig") ? [] : ["rscWebpackConfig in ServerClientOrBoth.js"]
      end

      def warn_non_object_literal_rsc_plugin_options_for_config(content)
        return unless non_object_literal_rsc_plugin_invocation_count(content).positive?

        warn_non_object_literal_rsc_plugin_options_once
      end

      def stale_inactive_rsc_plugin_messages(content, config_filename)
        return [] unless inactive_rsc_plugin_symbol_in_js_code?(content)

        [
          "stale #{inactive_rsc_plugin_class_name} in #{config_filename} " \
          "(found alongside #{rsc_plugin_class_name} — remove the inactive bundler plugin manually)"
        ]
      end

      def warn_non_object_literal_rsc_plugin_options_once
        return if @non_object_literal_rsc_plugin_options_warned

        @non_object_literal_rsc_plugin_options_warned = true
        GeneratorMessages.add_warning(
          "#{rsc_plugin_class_name} calls use non-object-literal options in one or more bundler configs, " \
          "so the generator cannot verify whether scoped clientReferences are configured. " \
          "Please verify your bundler configs manually."
        )
      end
    end
  end
end

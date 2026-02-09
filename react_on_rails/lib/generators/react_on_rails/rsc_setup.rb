# frozen_string_literal: true

require "rainbow"
require_relative "generator_messages"

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
      # Main entry point for RSC setup.
      # Orchestrates creation of all RSC-related files and configuration.
      #
      # Creates:
      # - config/webpack/rscWebpackConfig.js
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
      # @note This should be called before setup_rsc to warn users early
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

            To upgrade React:
              npm install react@19.0.3 react-dom@19.0.3

            Or with your package manager:
              pnpm add react@19.0.3 react-dom@19.0.3
              yarn add react@19.0.3 react-dom@19.0.3
          MSG
        elsif patch < 3
          GeneratorMessages.add_warning(<<~MSG.strip)
            ⚠️  React #{react_version} has known security vulnerabilities.

            Please upgrade to at least React 19.0.3:
              npm install react@19.0.3 react-dom@19.0.3

            See: CVE-2025-55182, CVE-2025-67779
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
          puts Rainbow("ℹ️  RSC config already in Pro initializer, skipping").yellow
          return
        end

        puts Rainbow("📝 Adding RSC config to Pro initializer...").yellow

        rsc_config = <<-CONFIG

  # React Server Components configuration
  config.enable_rsc_support = true
  config.rsc_bundle_js_file = "rsc-bundle.js"
  config.rsc_payload_generation_url_path = "rsc_payload/"
        CONFIG

        # Insert before the final 'end'
        gsub_file(initializer_path, /^end\s*\z/, "#{rsc_config}end")

        puts Rainbow("✅ Added RSC config to #{initializer_path}").green
      end

      def print_rsc_setup_banner
        puts Rainbow("\n#{'=' * 80}").magenta
        puts Rainbow("🚀 REACT SERVER COMPONENTS SETUP").magenta.bold
        puts Rainbow("=" * 80).magenta
      end

      def print_rsc_complete_banner
        puts Rainbow("=" * 80).magenta
        puts Rainbow("✅ React Server Components setup complete!").green
        puts Rainbow("=" * 80).magenta
      end

      def create_rsc_webpack_config
        webpack_config_path = "config/webpack/rscWebpackConfig.js"

        if File.exist?(File.join(destination_root, webpack_config_path))
          puts Rainbow("ℹ️  #{webpack_config_path} already exists, skipping").yellow
          return
        end

        puts Rainbow("📝 Creating RSC webpack config...").yellow

        rsc_template_path = "templates/rsc/base/config/webpack/rscWebpackConfig.js.tt"
        template(rsc_template_path, webpack_config_path)

        puts Rainbow("✅ Created #{webpack_config_path}").green
      end

      def add_rsc_to_procfile
        procfile_path = File.join(destination_root, "Procfile.dev")

        unless File.exist?(procfile_path)
          GeneratorMessages.add_warning(<<~MSG.strip)
            ⚠️  Procfile.dev not found. Skipping RSC bundle watcher addition.

            You'll need to add the RSC bundle watcher to your process manager manually:
              rsc-bundle: RSC_BUNDLE_ONLY=yes bin/shakapacker --watch
          MSG
          return
        end

        if File.read(procfile_path).include?("RSC_BUNDLE_ONLY")
          puts Rainbow("ℹ️  RSC bundle watcher already in Procfile.dev, skipping").yellow
          return
        end

        puts Rainbow("📝 Adding RSC bundle watcher to Procfile.dev...").yellow

        rsc_watcher_line = <<~PROCFILE

          # React on Rails Pro - RSC bundle watcher
          rsc-bundle: RSC_BUNDLE_ONLY=yes bin/shakapacker --watch
        PROCFILE

        append_to_file("Procfile.dev", rsc_watcher_line)

        puts Rainbow("✅ Added RSC bundle watcher to Procfile.dev").green
      end

      def create_hello_server_component
        hello_server_dir = "app/javascript/src/HelloServer"
        ror_components_dir = "#{hello_server_dir}/ror_components"
        components_dir = "#{hello_server_dir}/components"
        ext = component_extension(options)

        # Check if HelloServer already exists (check both jsx and tsx)
        if File.exist?(File.join(destination_root, "#{ror_components_dir}/HelloServer.jsx")) ||
           File.exist?(File.join(destination_root, "#{ror_components_dir}/HelloServer.tsx"))
          puts Rainbow("ℹ️  HelloServer component already exists, skipping").yellow
          return
        end

        puts Rainbow("📝 Creating HelloServer component...").yellow

        # Create directories
        empty_directory(ror_components_dir)
        empty_directory(components_dir)

        # Copy component files (uses jsx or tsx based on --typescript flag)
        copy_file("templates/rsc/base/app/javascript/src/HelloServer/ror_components/HelloServer.#{ext}",
                  "#{ror_components_dir}/HelloServer.#{ext}")
        copy_file("templates/rsc/base/app/javascript/src/HelloServer/components/HelloServer.#{ext}",
                  "#{components_dir}/HelloServer.#{ext}")

        puts Rainbow("✅ Created HelloServer component").green
      end

      def create_hello_server_controller
        controller_path = "app/controllers/hello_server_controller.rb"

        if File.exist?(File.join(destination_root, controller_path))
          puts Rainbow("ℹ️  HelloServerController already exists, skipping").yellow
          return
        end

        puts Rainbow("📝 Creating HelloServerController...").yellow

        copy_file("templates/rsc/base/app/controllers/hello_server_controller.rb", controller_path)

        puts Rainbow("✅ Created #{controller_path}").green
      end

      def create_hello_server_view
        view_path = "app/views/hello_server/index.html.erb"

        if File.exist?(File.join(destination_root, view_path))
          puts Rainbow("ℹ️  HelloServer view already exists, skipping").yellow
          return
        end

        puts Rainbow("📝 Creating HelloServer view...").yellow

        # Create views directory if needed
        empty_directory("app/views/hello_server")

        copy_file("templates/rsc/base/app/views/hello_server/index.html.erb", view_path)

        puts Rainbow("✅ Created #{view_path}").green
      end

      def add_rsc_routes
        routes_file = File.join(destination_root, "config/routes.rb")
        routes_content = File.read(routes_file)

        if routes_content.include?("rsc_payload_route")
          puts Rainbow("ℹ️  RSC routes already exist, skipping").yellow
          return
        end

        puts Rainbow("📝 Adding RSC routes...").yellow

        # Add rsc_payload_route (required for RSC payload requests)
        route "rsc_payload_route"

        # Add HelloServer route (RSC counterpart to hello_world)
        route "get 'hello_server', to: 'hello_server#index'"

        puts Rainbow("✅ Added RSC routes to config/routes.rb").green
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
        puts Rainbow("📝 Updating webpack configs for RSC...").yellow

        update_server_client_or_both_for_rsc
        update_server_webpack_config_for_rsc
        update_client_webpack_config_for_rsc

        puts Rainbow("✅ Updated webpack configs for RSC").green
      end

      def update_server_client_or_both_for_rsc
        config_path = "config/webpack/ServerClientOrBoth.js"
        full_path = File.join(destination_root, config_path)

        return unless File.exist?(full_path)

        content = File.read(full_path)

        # Skip if RSC is already configured
        return if content.include?("rscWebpackConfig")

        # Add RSC import after serverWebpackConfig import
        gsub_file(
          config_path,
          %r{(const \{ default: serverWebpackConfig \} = require\('\./serverWebpackConfig'\);)},
          "\\1\nconst rscWebpackConfig = require('./rscWebpackConfig');"
        )

        # Add rscConfig variable after serverConfig
        gsub_file(
          config_path,
          /^(\s*const serverConfig = serverWebpackConfig\(\);)$/,
          "\\1\n  const rscConfig = rscWebpackConfig();"
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
          %r{(\s*\} else \{\s*\n\s*// default is the standard client and server build)},
          "  #{rsc_bundle_handling}\n\\1"
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
        config_path = "config/webpack/serverWebpackConfig.js"
        full_path = File.join(destination_root, config_path)

        return unless File.exist?(full_path)

        content = File.read(full_path)

        # Skip if RSCWebpackPlugin is already configured
        return if content.include?("RSCWebpackPlugin")

        # Add RSCWebpackPlugin import after bundler require
        gsub_file(
          config_path,
          %r{(const bundler = config\.assets_bundler.*\n.*require\('@rspack/core'\).*\n.*: require\('webpack'\);)},
          "\\1\nconst { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');"
        )

        # Add rscBundle parameter to configureServer function
        gsub_file(
          config_path,
          /^const configureServer = \(\) => \{/,
          "// rscBundle parameter: when true, skips RSCWebpackPlugin (RSC bundle doesn't need it)\n" \
          "const configureServer = (rscBundle = false) => {"
        )

        # Add RSCWebpackPlugin to plugins after LimitChunkCountPlugin
        rsc_plugin_code = "\n  " \
                          "// Add RSC plugin for server bundle (handles client component references)\n  " \
                          "// Skip for RSC bundle - it doesn't need RSCWebpackPlugin\n  " \
                          "if (!rscBundle) {\n    " \
                          "serverWebpackConfig.plugins.push(new RSCWebpackPlugin({ isServer: true }));\n  " \
                          "}"
        gsub_file(
          config_path,
          /(serverWebpackConfig\.plugins\.unshift\(new bundler\.optimize\.LimitChunkCountPlugin.*\);)/,
          "\\1#{rsc_plugin_code}"
        )
      end

      def update_client_webpack_config_for_rsc
        config_path = "config/webpack/clientWebpackConfig.js"
        full_path = File.join(destination_root, config_path)

        return unless File.exist?(full_path)

        content = File.read(full_path)

        # Skip if RSCWebpackPlugin is already configured
        return if content.include?("RSCWebpackPlugin")

        # Add RSCWebpackPlugin import after commonWebpackConfig import
        gsub_file(
          config_path,
          %r{(const commonWebpackConfig = require\('\./commonWebpackConfig'\);)},
          "\\1\nconst { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');"
        )

        # Add RSCWebpackPlugin to client config before return statement
        rsc_plugin_code = "\n  " \
                          "// Add React Server Components plugin for client bundle\n  " \
                          "clientConfig.plugins.push(new RSCWebpackPlugin({ isServer: false }));"
        gsub_file(
          config_path,
          /^(\s*return clientConfig;)$/,
          "#{rsc_plugin_code}\n\n\\1"
        )
      end
    end
  end
end

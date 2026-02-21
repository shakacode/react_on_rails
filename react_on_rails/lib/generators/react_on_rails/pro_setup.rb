# frozen_string_literal: true

require "rainbow"
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
    module ProSetup
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
        puts Rainbow("\n#{'=' * 80}").cyan
        puts Rainbow("🚀 REACT ON RAILS PRO SETUP").cyan.bold
        puts Rainbow("=" * 80).cyan

        create_pro_initializer
        create_node_renderer
        add_pro_to_procfile
        update_webpack_config_for_pro

        puts Rainbow("=" * 80).cyan
        puts Rainbow("✅ React on Rails Pro setup complete!").green
        puts Rainbow("=" * 80).cyan
      end

      # Check if Pro gem is missing. Attempts auto-install via bundle add.
      # @param force [Boolean] When true, always checks (default: only if use_pro?).
      # @return [Boolean] true if Pro gem is missing and could not be installed
      def missing_pro_gem?(force: false)
        return false unless force || use_pro?
        return false if pro_gem_installed?

        # Try auto-installing (similar to ensure_shakapacker_in_gemfile in install_generator)
        puts Rainbow("📝 Adding react_on_rails_pro to Gemfile...").yellow
        if Bundler.with_unbundled_env { system("bundle add react_on_rails_pro --strict") }
          @pro_gem_installed = nil
          return false
        end

        context_line = if options.key?(:pro) || options.key?(:rsc)
                         flag = options[:rsc] ? "--rsc" : "--pro"
                         "You specified #{flag}, which requires the react_on_rails_pro gem."
                       else
                         "This generator requires the react_on_rails_pro gem."
                       end

        GeneratorMessages.add_error(<<~MSG.strip)
          🚫 Failed to auto-install react_on_rails_pro gem.

          #{context_line}

          Please add manually to your Gemfile:
            gem 'react_on_rails_pro', '>= 16.3.0'

          Then run: bundle install

          More info: https://www.shakacode.com/react-on-rails-pro/
        MSG
        true
      end

      private

      def create_pro_initializer
        initializer_path = "config/initializers/react_on_rails_pro.rb"

        if File.exist?(File.join(destination_root, initializer_path))
          puts Rainbow("ℹ️  #{initializer_path} already exists, skipping").yellow
          return
        end

        puts Rainbow("📝 Creating React on Rails Pro initializer...").yellow

        pro_template_path = "templates/pro/base/config/initializers/react_on_rails_pro.rb.tt"
        template(pro_template_path, initializer_path)

        puts Rainbow("✅ Created #{initializer_path}").green
      end

      def create_node_renderer
        node_renderer_path = "client/node-renderer.js"

        if File.exist?(File.join(destination_root, node_renderer_path))
          puts Rainbow("ℹ️  #{node_renderer_path} already exists, skipping").yellow
          return
        end

        puts Rainbow("📝 Creating Node Renderer bootstrap...").yellow

        # Ensure client directory exists
        FileUtils.mkdir_p(File.join(destination_root, "client"))

        template_path = "templates/pro/base/client/node-renderer.js"
        copy_file(template_path, node_renderer_path)

        puts Rainbow("✅ Created #{node_renderer_path}").green
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
          puts Rainbow("ℹ️  Node Renderer already in Procfile.dev, skipping").yellow
          return
        end

        puts Rainbow("📝 Adding Node Renderer to Procfile.dev...").yellow

        node_renderer_line = <<~PROCFILE

          # React on Rails Pro - Node Renderer for SSR
          node-renderer: RENDERER_LOG_LEVEL=debug RENDERER_PORT=3800 node client/node-renderer.js
        PROCFILE

        append_to_file("Procfile.dev", node_renderer_line)

        puts Rainbow("✅ Added Node Renderer to Procfile.dev").green
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
        webpack_config_path = File.join(destination_root, "config/webpack/serverWebpackConfig.js")

        unless File.exist?(webpack_config_path)
          puts Rainbow("ℹ️  serverWebpackConfig.js not found, skipping webpack update").yellow
          return
        end

        content = File.read(webpack_config_path)

        # Check if Pro settings are already enabled (not commented)
        if content.include?("libraryTarget: 'commonjs2',") &&
           !content.include?("// libraryTarget: 'commonjs2',")
          puts Rainbow("ℹ️  Webpack config already has Pro settings enabled, skipping").yellow
          return
        end

        puts Rainbow("📝 Updating serverWebpackConfig.js for Pro...").yellow

        webpack_config = "config/webpack/serverWebpackConfig.js"

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

        # Update ServerClientOrBoth.js import style
        update_server_client_or_both_import

        verify_pro_webpack_transforms(webpack_config)
        puts Rainbow("✅ Updated webpack configs for Pro").green
      end

      def add_extract_loader_to_server_config(webpack_config, content)
        # Skip if extractLoader already exists
        return if content.include?("function extractLoader")

        extract_loader_code = <<~JS.chomp


          function extractLoader(rule, loaderName) {
            if (!Array.isArray(rule.use)) return null;
            return rule.use.find((item) => {
              const testValue = typeof item === 'string' ? item : item.loader;
              return testValue && testValue.includes(loaderName);
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
        # Skip if Babel SSR caller already exists
        return if content.include?("babelLoader.options.caller")

        babel_ssr_code = "\n\n      " \
                         "// Set SSR caller for Babel (if using Babel instead of SWC)\n      " \
                         "const babelLoader = extractLoader(rule, 'babel-loader');\n      " \
                         "if (babelLoader && babelLoader.options) {\n        " \
                         "babelLoader.options.caller = { ssr: true };\n      " \
                         "}"

        # Insert after cssLoader.options.modules = { exportOnlyLocals: true }; block
        gsub_file(
          webpack_config,
          /(cssLoader\.options\.modules = \{ exportOnlyLocals: true \};\s*\n\s*\})/,
          "\\1#{babel_ssr_code}"
        )
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
        missing = []
        missing << "libraryTarget: 'commonjs2'" unless content.include?("libraryTarget: 'commonjs2',")
        missing << "function extractLoader" unless content.include?("function extractLoader")
        missing << "serverWebpackConfig.target = 'node'" unless content.include?("serverWebpackConfig.target = 'node'")
        missing << "module.exports = {" unless content.include?("module.exports = {")
        return if missing.empty?

        GeneratorMessages.add_warning(<<~MSG.strip)
          ⚠️  Some Pro webpack transforms may not have applied correctly.

          The following expected patterns were not found in #{webpack_config}:
          #{missing.map { |m| "  - #{m}" }.join("\n")}

          This can happen if your webpack config has been customized.
          Please verify #{webpack_config} manually.
        MSG
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
      end
    end
  end
end

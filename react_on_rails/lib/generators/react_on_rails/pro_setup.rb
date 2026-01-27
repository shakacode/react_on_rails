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

      # Check if Pro gem is missing.
      #
      # @param force [Boolean] When true, always performs the check.
      #   When false (default), only checks if Pro is required (use_pro? returns true).
      #   Use force: true in standalone generators where Pro is always required.
      # @return [Boolean] true if Pro gem is missing
      def missing_pro_gem?(force: false)
        return false unless force || use_pro?
        return false if pro_gem_installed?

        # Detect context: install_generator defines :pro/:rsc options, standalone generators don't
        context_line = if options.key?(:pro) || options.key?(:rsc)
                         flag = options[:rsc] ? "--rsc" : "--pro"
                         "You specified #{flag}, which requires the react_on_rails_pro gem."
                       else
                         "This generator requires the react_on_rails_pro gem."
                       end

        GeneratorMessages.add_error(<<~MSG.strip)
          🚫 React on Rails Pro gem is not installed.

          #{context_line}

          Add to your Gemfile:
            gem 'react_on_rails_pro', '~> 16.2'

          Then run: bundle install

          Try Pro free! Email justin@shakacode.com for an evaluation license.
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

      # Update serverWebpackConfig.js to enable Pro settings.
      # This is needed for standalone Pro upgrades where the base install
      # created webpack configs without Pro settings enabled.
      #
      # Uncomments:
      # - libraryTarget: 'commonjs2' (required for Node Renderer)
      # - serverWebpackConfig.target = 'node' (required for Node.js modules)
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

        # Uncomment libraryTarget: 'commonjs2'
        library_target_pattern = %r{// If using the React on Rails Pro.*\n\s*// libraryTarget: 'commonjs2',}
        library_target_replacement = "// Required for React on Rails Pro Node Renderer\n    " \
                                     "libraryTarget: 'commonjs2',"
        gsub_file(webpack_config, library_target_pattern, library_target_replacement)

        # Uncomment serverWebpackConfig.target = 'node'
        target_node_pattern = %r{// If using the React on Rails Pro.*\n\s*// serverWebpackConfig\.target = 'node'}
        target_node_replacement = "// React on Rails Pro uses Node renderer, so target must be 'node'\n  " \
                                  "serverWebpackConfig.target = 'node'"
        gsub_file(webpack_config, target_node_pattern, target_node_replacement)

        puts Rainbow("✅ Updated serverWebpackConfig.js for Pro").green
      end
    end
  end
end

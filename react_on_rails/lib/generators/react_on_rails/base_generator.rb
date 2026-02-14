# frozen_string_literal: true

require "rails/generators"
require "fileutils"
require_relative "generator_messages"
require_relative "generator_helper"
require_relative "js_dependency_manager"
module ReactOnRails
  module Generators
    class BaseGenerator < Rails::Generators::Base
      include GeneratorHelper
      include JsDependencyManager

      Rails::Generators.hide_namespace(namespace)
      source_root(File.expand_path("templates", __dir__))

      # --redux
      class_option :redux,
                   type: :boolean,
                   default: false,
                   desc: "Install Redux package and Redux version of Hello World Example",
                   aliases: "-R"

      # --rspack
      class_option :rspack,
                   type: :boolean,
                   default: false,
                   desc: "Use Rspack instead of Webpack as the bundler"

      # Hidden option: signals that Shakapacker was just installed by install_generator.
      # When true, copy_packer_config uses force: true to overwrite Shakapacker's default config
      # without prompting, since we know it's a fresh default (not user-customized).
      class_option :shakapacker_just_installed,
                   type: :boolean,
                   default: false,
                   hide: true

      def add_hello_world_route
        route "get 'hello_world', to: 'hello_world#index'"
      end

      def create_react_directories
        # Create auto-bundling directory structure for non-Redux components only
        # Redux components handle their own directory structure
        return if options.redux?

        empty_directory("app/javascript/src/HelloWorld/ror_components")
      end

      def copy_base_files
        base_path = "base/base/"
        base_files = %w[app/controllers/hello_world_controller.rb
                        app/views/layouts/hello_world.html.erb
                        Procfile.dev
                        Procfile.dev-static-assets
                        Procfile.dev-prod-assets
                        .dev-services.yml.example
                        bin/shakapacker-precompile-hook]
        base_templates = %w[config/initializers/react_on_rails.rb]
        base_files.each { |file| copy_file("#{base_path}#{file}", file) }
        base_templates.each do |file|
          template("#{base_path}/#{file}.tt", file)
        end

        # Make the hook script executable (copy_file guarantees it exists)
        File.chmod(0o755, File.join(destination_root, "bin/shakapacker-precompile-hook"))
      end

      def copy_js_bundle_files
        base_path = "base/base/"
        base_files = %w[app/javascript/packs/server-bundle.js]

        # Only copy HelloWorld.module.css for non-Redux components
        # Redux components handle their own CSS files
        base_files << "app/javascript/src/HelloWorld/ror_components/HelloWorld.module.css" unless options.redux?

        base_files.each { |file| copy_file("#{base_path}#{file}", file) }
      end

      def copy_webpack_config
        puts "Adding Webpack config"
        base_path = "base/base"
        base_files = %w[babel.config.js
                        config/webpack/clientWebpackConfig.js
                        config/webpack/commonWebpackConfig.js
                        config/webpack/test.js
                        config/webpack/development.js
                        config/webpack/production.js
                        config/webpack/serverWebpackConfig.js
                        config/webpack/generateWebpackConfigs.js]
        config = {
          message: "// The source code including full typescript support is available at:"
        }
        base_files.each { |file| template("#{base_path}/#{file}.tt", file, config) }

        # Handle webpack.config.js separately with smart replacement
        copy_webpack_main_config(base_path, config)
      end

      def copy_packer_config
        base_path = "base/base/"
        config = "config/shakapacker.yml"

        if options.shakapacker_just_installed?
          puts "Replacing Shakapacker default config with React on Rails version"
          # Shakapacker's installer just created this file from scratch (no pre-existing config).
          # Safe to overwrite silently with RoR's version-aware template (e.g., private_output_path).
          template("#{base_path}#{config}.tt", config, force: true)
        else
          puts "Adding Shakapacker #{ReactOnRails::PackerUtils.shakapacker_version} config"
          # Shakapacker was pre-installed — prompt before overwriting in case of user customizations.
          template("#{base_path}#{config}.tt", config)
        end

        # Configure bundler-specific settings
        configure_rspack_in_shakapacker if options.rspack?

        # Always ensure precompile_hook is configured (Shakapacker 9.0+ only)
        configure_precompile_hook_in_shakapacker
      end

      def add_base_gems_to_gemfile
        run "bundle"
      end

      def update_gitignore_for_auto_registration
        gitignore_path = File.join(destination_root, ".gitignore")
        return unless File.exist?(gitignore_path)

        gitignore_content = File.read(gitignore_path)

        additions = []
        additions << "**/generated/**" unless gitignore_content.include?("**/generated/**")
        additions << "ssr-generated" unless gitignore_content.include?("ssr-generated")

        return if additions.empty?

        append_to_file ".gitignore" do
          lines = ["\n# Generated React on Rails packs"]
          lines.concat(additions)
          "#{lines.join("\n")}\n"
        end
      end

      def append_to_spec_rails_helper
        rails_helper = File.join(destination_root, "spec/rails_helper.rb")
        if File.exist?(rails_helper)
          add_configure_rspec_to_compile_assets(rails_helper)
        else
          spec_helper = File.join(destination_root, "spec/spec_helper.rb")
          add_configure_rspec_to_compile_assets(spec_helper) if File.exist?(spec_helper)
        end
      end

      CONFIGURE_RSPEC_TO_COMPILE_ASSETS = <<-STR.strip_heredoc
        RSpec.configure do |config|
          # Ensure that if we are running js tests, we are using latest webpack assets
          # This will use the defaults of :js and :server_rendering meta tags
          ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
        end
      STR

      private

      def copy_webpack_main_config(base_path, config)
        webpack_config_path = "config/webpack/webpack.config.js"

        if File.exist?(webpack_config_path)
          existing_content = File.read(webpack_config_path)

          # Check if it's the standard Shakapacker config that we can safely replace
          if standard_shakapacker_config?(existing_content)
            # Remove the file first to avoid conflict prompt, then recreate it
            remove_file(webpack_config_path, verbose: false)
            # Show what we're doing
            puts "   #{set_color('replace', :green)}  #{webpack_config_path} " \
                 "(auto-upgrading from standard Shakapacker to React on Rails config)"
            template("#{base_path}/#{webpack_config_path}.tt", webpack_config_path, config)
          elsif react_on_rails_config?(existing_content)
            puts "   #{set_color('identical', :blue)}  #{webpack_config_path} " \
                 "(already React on Rails compatible)"
            # Skip - don't need to do anything
          else
            handle_custom_webpack_config(base_path, config, webpack_config_path)
          end
        else
          # File doesn't exist, create it
          template("#{base_path}/#{webpack_config_path}.tt", webpack_config_path, config)
        end
      end

      def handle_custom_webpack_config(base_path, config, webpack_config_path)
        # Custom config - ask user
        puts "\n#{set_color('NOTICE:', :yellow)} Your webpack.config.js appears to be customized."
        puts "React on Rails needs to replace it with an environment-specific loader."
        puts "Your current config will be backed up to webpack.config.js.backup"

        if yes?("Replace webpack.config.js with React on Rails version? (Y/n)")
          # Create backup
          backup_path = "#{webpack_config_path}.backup"
          if File.exist?(webpack_config_path)
            FileUtils.cp(webpack_config_path, backup_path)
            puts "   #{set_color('create', :green)}  #{backup_path} (backup of your custom config)"
          end

          template("#{base_path}/#{webpack_config_path}.tt", webpack_config_path, config)
        else
          puts "   #{set_color('skip', :yellow)}  #{webpack_config_path}"
          puts "   #{set_color('WARNING:', :red)} React on Rails may not work correctly " \
               "without the environment-specific webpack config"
        end
      end

      def standard_shakapacker_config?(content)
        # Get the expected default config based on Shakapacker version
        expected_configs = shakapacker_default_configs

        # Check if the content matches any of the known default configurations
        expected_configs.any? { |config| content_matches_template?(content, config) }
      end

      def content_matches_template?(content, template)
        # Normalize whitespace and compare
        normalize_config_content(content) == normalize_config_content(template)
      end

      def normalize_config_content(content)
        # Remove comments, normalize whitespace, and clean up for comparison
        content.gsub(%r{//.*$}, "")                    # Remove single-line comments
               .gsub(%r{/\*.*?\*/}m, "")               # Remove multi-line comments
               .gsub(/\s+/, " ")                       # Normalize whitespace
               .strip
      end

      def shakapacker_default_configs
        configs = []

        # Shakapacker v7+ (generateWebpackConfig function)
        configs << <<~CONFIG
          // See the shakacode/shakapacker README and docs directory for advice on customizing your webpackConfig.
          const { generateWebpackConfig } = require('shakapacker')

          const webpackConfig = generateWebpackConfig()

          module.exports = webpackConfig
        CONFIG

        # Shakapacker v6 (webpackConfig object)
        configs << <<~CONFIG
          const { webpackConfig } = require('shakapacker')

          // See the shakacode/shakapacker README and docs directory for advice on customizing your webpackConfig.

          module.exports = webpackConfig
        CONFIG

        # Also check without comments for variations
        configs << <<~CONFIG
          const { generateWebpackConfig } = require('shakapacker')
          const webpackConfig = generateWebpackConfig()
          module.exports = webpackConfig
        CONFIG

        configs << <<~CONFIG
          const { webpackConfig } = require('shakapacker')
          module.exports = webpackConfig
        CONFIG

        configs
      end

      def react_on_rails_config?(content)
        # Check if it already has React on Rails environment-specific loading
        content.include?("envSpecificConfig") || content.include?("env.nodeEnv")
      end

      # From https://github.com/rails/rails/blob/4c940b2dbfb457f67c6250b720f63501d74a45fd/railties/lib/rails/generators/rails/app/app_generator.rb
      def app_name
        @app_name ||= (defined_app_const_base? ? defined_app_name : File.basename(destination_root))
                      .tr("\\", "").tr(". ", "_")
      end

      def defined_app_name
        defined_app_const_base.underscore
      end

      def defined_app_const_base
        Rails.respond_to?(:application) && defined?(Rails::Application) &&
          Rails.application.is_a?(Rails::Application) && Rails.application.class.name.sub(/::Application$/, "")
      end

      alias defined_app_const_base? defined_app_const_base

      def app_const_base
        @app_const_base ||= defined_app_const_base || app_name.gsub(/\W/, "_").squeeze("_").camelize
      end

      def app_const
        @app_const ||= "#{app_const_base}::Application"
      end

      def add_configure_rspec_to_compile_assets(helper_file)
        search_str = "RSpec.configure do |config|"
        gsub_file(helper_file, search_str, CONFIGURE_RSPEC_TO_COMPILE_ASSETS)
      end

      def configure_rspack_in_shakapacker
        shakapacker_config_path = "config/shakapacker.yml"
        return unless File.exist?(shakapacker_config_path)

        puts Rainbow("🔧 Configuring Shakapacker for Rspack...").yellow

        # Use regex replacement to preserve file structure (comments, anchors, aliases)
        # This replaces ALL occurrences of assets_bundler, not just in default section
        # Using gsub_file (Thor method) for consistency with Rails generator patterns
        gsub_file(
          shakapacker_config_path,
          /^(\s*assets_bundler:\s*)["']?webpack["']?(\s*(?:#.*)?)$/,
          '\1rspack\2'
        )

        # Update javascript_transpiler to swc (rspack works best with SWC)
        gsub_file(
          shakapacker_config_path,
          /^(\s*javascript_transpiler:\s*)["']?babel["']?(\s*(?:#.*)?)$/,
          '\1swc\2'
        )

        puts Rainbow("✅ Updated shakapacker.yml for Rspack").green
      end

      def configure_precompile_hook_in_shakapacker
        # precompile_hook is only supported in Shakapacker 9.0+
        return unless ReactOnRails::PackerUtils.shakapacker_version_requirement_met?("9.0.0")

        shakapacker_config_path = "config/shakapacker.yml"
        return unless File.exist?(shakapacker_config_path)

        content = File.read(shakapacker_config_path)

        # Already has an active (non-commented) precompile_hook configured? Don't overwrite.
        return if content.match?(/^\s+precompile_hook:\s*['"][^'"]+['"]/)

        # Replace the commented placeholder with the actual value
        # Shakapacker 9.x default config has: # precompile_hook: ~
        gsub_file shakapacker_config_path,
                  /^(\s*)#\s*precompile_hook:\s*~\s*$/,
                  "\\1precompile_hook: 'bin/shakapacker-precompile-hook'"

        puts Rainbow("✅ Configured precompile_hook in shakapacker.yml").green
      end
    end
  end
end

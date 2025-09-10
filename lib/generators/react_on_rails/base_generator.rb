# frozen_string_literal: true

require "rails/generators"
require_relative "generator_messages"
require_relative "generator_helper"
module ReactOnRails
  module Generators
    class BaseGenerator < Rails::Generators::Base
      include GeneratorHelper
      Rails::Generators.hide_namespace(namespace)
      source_root(File.expand_path("templates", __dir__))

      # --redux
      class_option :redux,
                   type: :boolean,
                   default: false,
                   desc: "Install Redux gems and Redux version of Hello World Example",
                   aliases: "-R"

      def add_hello_world_route
        route "get 'hello_world', to: 'hello_world#index'"
      end

      def create_react_directories
        dirs = %w[components]
        dirs.each { |name| empty_directory("app/javascript/bundles/HelloWorld/#{name}") }
      end

      def copy_base_files
        base_path = "base/base/"
        base_files = %w[app/controllers/hello_world_controller.rb
                        app/views/layouts/hello_world.html.erb
                        Procfile.dev
                        Procfile.dev-static
                        Procfile.dev-static-assets
                        Procfile.dev-prod-assets]
        base_templates = %w[config/initializers/react_on_rails.rb]
        base_files.each { |file| copy_file("#{base_path}#{file}", file) }
        base_templates.each do |file|
          template("#{base_path}/#{file}.tt", file, { packer_type: ReactOnRails::PackerUtils.packer_type })
        end
      end

      def copy_js_bundle_files
        base_path = "base/base/"
        base_files = %w[app/javascript/packs/server-bundle.js
                        app/javascript/bundles/HelloWorld/components/HelloWorldServer.js
                        app/javascript/bundles/HelloWorld/components/HelloWorld.module.css]
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
                        config/webpack/webpack.config.js
                        config/webpack/webpackConfig.js]
        config = {
          message: "// The source code including full typescript support is available at:"
        }
        base_files.each { |file| template("#{base_path}/#{file}.tt", file, config) }
      end

      def copy_packer_config
        puts "Adding Shakapacker #{ReactOnRails::PackerUtils.shakapacker_version} config"
        base_path = "base/base/"
        config = "config/shakapacker.yml"
        copy_file("#{base_path}#{config}", config)
      end

      def add_base_gems_to_gemfile
        run "bundle"
      end

      def add_js_dependencies
        major_minor_patch_only = /\A\d+\.\d+\.\d+\z/
        if ReactOnRails::VERSION.match?(major_minor_patch_only)
          package_json.manager.add(["react-on-rails@#{ReactOnRails::VERSION}"])
        else
          # otherwise add latest
          puts "Adding the latest react-on-rails NPM module. Double check this is correct in package.json"
          package_json.manager.add(["react-on-rails"])
        end

        puts "Adding React dependencies"
        package_json.manager.add([
                                   "react",
                                   "react-dom",
                                   "@babel/preset-react",
                                   "prop-types",
                                   "babel-plugin-transform-react-remove-prop-types",
                                   "babel-plugin-macros"
                                 ])

        puts "Adding CSS handlers"

        package_json.manager.add(%w[
                                   css-loader
                                   css-minimizer-webpack-plugin
                                   mini-css-extract-plugin
                                   style-loader
                                 ])

        puts "Adding dev dependencies"
        package_json.manager.add([
                                   "@pmmmwh/react-refresh-webpack-plugin",
                                   "react-refresh"
                                 ], type: :dev)
      end

      def append_to_spec_rails_helper
        rails_helper = File.join(destination_root, "spec/rails_helper.rb")
        if File.exist?(rails_helper)
          add_configure_rspec_to_compile_assets(rails_helper)
        else
          spec_helper = File.join(destination_root, "spec/spec_helper.rb")
          if File.exist?(spec_helper)
            add_configure_rspec_to_compile_assets(spec_helper)
          else
            # rubocop:disable Layout/EmptyLinesAroundArguments
            GeneratorMessages.add_info(
              <<-MSG.strip_heredoc

              We did not find a spec/rails_helper.rb or spec/spec_helper.rb to add
              the React on Rails Test helper, which ensures that if we are running
              js tests, then we are using latest webpack assets. You can later add
              this to your rspec config:

              # This will use the defaults of :js and :server_rendering meta tags
              ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
              MSG
            )
            # rubocop:enable Layout/EmptyLinesAroundArguments

          end
        end
      end

      CONFIGURE_RSPEC_TO_COMPILE_ASSETS = <<-STR.strip_heredoc
        RSpec.configure do |config|
          # Ensure that if we are running js tests, we are using latest webpack assets
          # This will use the defaults of :js and :server_rendering meta tags
          ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
      STR

      private

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
    end
  end
end

# frozen_string_literal: true

require "rails/generators"
require_relative "generator_messages"
require_relative "generator_helper"

module ReactOnRails
  module Generators
    class BaseGenerator < Rails::Generators::Base
      include GeneratorHelper
      Rails::Generators.hide_namespace(namespace)
      source_root(File.expand_path("../templates", __FILE__))

      # --redux
      class_option :redux,
                   type: :boolean,
                   default: false,
                   desc: "Install Redux gems and Redux version of Hello World Example",
                   aliases: "-R"

      def add_hello_world_route
        route "get 'hello_world', to: 'hello_world#index'"
      end

      def update_git_ignore
        data = <<-DATA.strip_heredoc
          # React on Rails
          npm-debug.log*
          node_modules

          # Generated js bundles
          /public/webpack/*
        DATA

        if dest_file_exists?(".gitignore")
          append_to_file(".gitignore", data)
        else
          GeneratorMessages.add_error(setup_file_error(".gitignore", data))
        end
      end

      def create_react_directories
        dirs = %w[components containers startup]
        dirs.each { |name| empty_directory("client/app/bundles/HelloWorld/#{name}") }
      end

      def copy_base_files
        base_path = "base/base/"
        base_files = %w[app/controllers/hello_world_controller.rb
                        config/webpacker_lite.yml
                        client/.babelrc
                        client/webpack.config.js
                        client/REACT_ON_RAILS_CLIENT_README.md]
        base_files.each { |file| copy_file("#{base_path}#{file}", file) }
      end

      def template_base_files
        base_path = "base/base/"
        %w[app/views/layouts/hello_world.html.erb
           config/initializers/react_on_rails.rb
           Procfile.dev
           client/package.json].each { |file| template("#{base_path}#{file}.tt", file) }
      end

      def template_package_json
        if dest_file_exists?("package.json")
          add_yarn_postinstall_script_in_package_json
        else
          template("base/base/package.json", "package.json")
        end
      end

      def add_base_gems_to_gemfile
        append_to_file("Gemfile", "\ngem 'mini_racer', platforms: :ruby\ngem 'webpacker_lite'\n")
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
            GeneratorMessages.add_info(
              <<-MSG.strip_heredoc
              Did not find spec/rails_helper.rb or spec/spec_helper.rb to add
                # Ensure that if we are running js tests, we are using latest webpack assets
                # This will use the defaults of :js and :server_rendering meta tags
                ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
              MSG
            )
          end
        end
      end

      CONFIGURE_RSPEC_TO_COMPILE_ASSETS = <<-STR.strip_heredoc
        RSpec.configure do |config|
          # Ensure that if we are running js tests, we are using latest webpack assets
          # This will use the defaults of :js and :server_rendering meta tags
          ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
      STR

      def print_helpful_message
        message = <<-MSG.strip_heredoc

          What to do next:

            - Include your webpack assets to your application layout.

              <%= javascript_pack_tag 'webpack-bundle' %>

            - Ensure your bundle and yarn installs of dependencies are up to date.

                bundle && yarn

            - Run the foreman command to start the rails server and run webpack in watch mode.

                foreman start -f Procfile.dev

            - Visit http://localhost:3000/hello_world and see your React On Rails app running!
        MSG
        GeneratorMessages.add_info(message)
      end

      private

      def add_yarn_postinstall_script_in_package_json
        client_package_json = File.join(destination_root, "package.json")
        contents = File.read(client_package_json)
        postinstall = %("postinstall": "cd client && yarn install")
        if contents =~ /"scripts" *:/
          replacement = <<-STRING
  "scripts": {
    #{postinstall},
STRING
          regexp = / {2}"scripts": {/
        else
          regexp = /^{/
          replacement = <<-STRING.strip_heredoc
            {
              "scripts": {
                #{postinstall}
              },
          STRING
        end

        contents.gsub!(regexp, replacement)
        File.open(client_package_json, "w+") { |f| f.puts contents }
      end

      # From https://github.com/rails/rails/blob/4c940b2dbfb457f67c6250b720f63501d74a45fd/railties/lib/rails/generators/rails/app/app_generator.rb
      def app_name
        @app_name ||= (defined_app_const_base? ? defined_app_name : File.basename(destination_root))
                      .tr('\\', "").tr(". ", "_")
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

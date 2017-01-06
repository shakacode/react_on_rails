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
          /app/assets/webpack/*
        DATA

        if dest_file_exists?(".gitignore")
          append_to_file(".gitignore", data)
        else
          GeneratorMessages.add_error(setup_file_error(".gitignore", data))
        end
      end

      def update_application_js
        data = <<-DATA.strip_heredoc
          //= require webpack-bundle

        DATA

        app_js_path = "app/assets/javascripts/application.js"
        found_app_js = dest_file_exists?(app_js_path) || dest_file_exists?("#{app_js_path}.coffee")
        if found_app_js
          prepend_to_file(found_app_js, data)
        else
          create_file(app_js_path, data)
        end
      end

      def strip_application_js_of_double_blank_lines
        application_js = File.join(destination_root, "app/assets/javascripts/application.js")
        gsub_file(application_js, /^\n^\n/, "\n")
      end

      def create_react_directories
        dirs = %w(components containers startup)
        dirs.each { |name| empty_directory("client/app/bundles/HelloWorld/#{name}") }
      end

      def copy_base_files
        base_path = "base/base/"
        base_files = %w(app/controllers/hello_world_controller.rb
                        client/.babelrc
                        client/webpack.config.js
                        client/REACT_ON_RAILS_CLIENT_README.md)
        base_files.each { |file| copy_file("#{base_path}#{file}", file) }
      end

      def template_base_files
        base_path = "base/base/"
        %w(config/initializers/react_on_rails.rb
           Procfile.dev
           package.json
           client/package.json).each { |file| template("#{base_path}#{file}.tt", file) }
      end

      def add_base_gems_to_gemfile
        append_to_file("Gemfile", "\ngem 'mini_racer', platforms: :ruby\n")
      end

      ASSETS_RB_APPEND = <<-DATA.strip_heredoc
# Add client/assets/ folders to asset pipeline's search path.
# If you do not want to move existing images and fonts from your Rails app
# you could also consider creating symlinks there that point to the original
# rails directories. In that case, you would not add these paths here.
# If you have a different server bundle file than your client bundle, you'll
# need to add it here, like this:
# Rails.application.config.assets.precompile += %w( server-bundle.js )

# Add folder with webpack generated assets to assets.paths
Rails.application.config.assets.paths << Rails.root.join("app", "assets", "webpack")
      DATA

      def append_to_assets_initializer
        assets_initializer = File.join(destination_root, "config/initializers/assets.rb")
        if File.exist?(assets_initializer)
          append_to_file(assets_initializer, ASSETS_RB_APPEND)
        else
          create_file(assets_initializer, ASSETS_RB_APPEND)
        end
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

            - Ensure your bundle and npm are up to date.

                bundle && npm i

            - Run the foreman command to start the rails server and run webpack in watch mode.

                foreman start -f Procfile.dev

            - Visit http://localhost:3000/hello_world and see your React On Rails app running!
        MSG
        GeneratorMessages.add_info(message)
      end

      private

      def add_configure_rspec_to_compile_assets(helper_file)
        search_str = "RSpec.configure do |config|"
        gsub_file(helper_file, search_str, CONFIGURE_RSPEC_TO_COMPILE_ASSETS)
      end
    end
  end
end

require "rails/generators"
require_relative "generator_messages"
require_relative "generator_helper"

module ReactOnRails
  module Generators
    class BaseGenerator < Rails::Generators::Base # rubocop:disable Metrics/ClassLength
      include GeneratorHelper
      Rails::Generators.hide_namespace(namespace)
      source_root(File.expand_path("../templates", __FILE__))

      # --redux
      class_option :redux,
                   type: :boolean,
                   default: false,
                   desc: "Install Redux gems and Redux version of Hello World Example",
                   aliases: "-R"
      # --server-rendering
      class_option :server_rendering,
                   type: :boolean,
                   default: false,
                   desc: "Configure for server-side rendering of webpack JavaScript",
                   aliases: "-S"

      def add_hello_world_route
        route "get 'hello_world', to: 'hello_world#index'"
      end

      def create_client_assets_directories
        empty_directory("client/assets")
        empty_directory("client/assets/stylesheets")
        empty_directory_with_keep_file("client/assets/fonts")
        empty_directory_with_keep_file("client/assets/images")
      end

      def update_git_ignore
        data = <<-DATA.strip_heredoc
          # React on Rails
          npm-debug.log
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
          // DO NOT REQUIRE jQuery or jQuery-ujs in this file!
          // DO NOT REQUIRE TREE!

          // since it is exposing jQuery and jQuery-ujs

          //= require vendor-bundle
          //= require app-bundle

        DATA

        app_js_path = "app/assets/javascripts/application.js"
        found_app_js = dest_file_exists?(app_js_path) || dest_file_exists?(app_js_path + ".coffee")
        if found_app_js
          prepend_to_file(found_app_js, data)
        else
          create_file(app_js_path, data)
        end
      end

      def strip_application_js_of_incompatible_sprockets_statements
        application_js = File.join(destination_root, "app/assets/javascripts/application.js")
        gsub_file(application_js, "//= require jquery_ujs", "// require jquery_ujs")
        gsub_file(application_js, %r{//= require jquery$}, "// require jquery")
        gsub_file(application_js, %r{//= require_tree \.$}, "// require_tree .")
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
        %w(app/controllers/hello_world_controller.rb
           client/.babelrc
           client/webpack.client.base.config.js
           client/webpack.client.rails.config.js
           package.json).each { |file| copy_file(base_path + file, file) }
      end

      def template_base_files
        base_path = "base/base/"
        %w(config/initializers/react_on_rails.rb
           Procfile.dev
           app/views/hello_world/index.html.erb
           client/app/bundles/HelloWorld/components/HelloWorldWidget.jsx
           client/package.json).each { |file| template(base_path + file + ".tt", file) }
      end

      def template_client_registration_file
        filename = "clientRegistration.jsx"
        location = "client/app/bundles/HelloWorld/startup"
        template("base/base/#{location}/clientRegistration.jsx.tt", "#{location}/#{filename}")
      end

      def install_server_rendering_files_if_enabled
        return unless options.server_rendering?
        base_path = "base/server_rendering/"
        %w(client/webpack.server.rails.config.js
           client/app/bundles/HelloWorld/startup/serverRegistration.jsx).each do |file|
          copy_file(base_path + file, file)
        end
      end

      ASSETS_RB_APPEND = <<-DATA.strip_heredoc
# Add client/assets/ folders to asset pipeline's search path.
# If you do not want to move existing images and fonts from your Rails app
# you could also consider creating symlinks there that point to the original
# rails directories. In that case, you would not add these paths here.
Rails.application.config.assets.paths << Rails.root.join("client", "assets", "stylesheets")
Rails.application.config.assets.paths << Rails.root.join("client", "assets", "images")
Rails.application.config.assets.paths << Rails.root.join("client", "assets", "fonts")
Rails.application.config.assets.precompile += %w( server-bundle.js )

# Add folder with webpack generated assets to assets.paths
Rails.application.config.assets.paths << Rails.root.join("app", "assets", "webpack")
      DATA

      def append_to_assets_initializer
        assets_intializer = File.join(destination_root, "config/initializers/assets.rb")
        if File.exist?(assets_intializer)
          append_to_file(assets_intializer, ASSETS_RB_APPEND)
        else
          create_file(assets_intializer, ASSETS_RB_APPEND)
        end
      end

      def print_helpful_message
        message = <<-MSG.strip_heredoc

          What to do next:

            - Ensure your bundle and npm are up to date.

                bundle && npm i

            - Run the npm rails-server command to load the rails server.

                npm run rails-server

            - Visit http://localhost:3000/hello_world and see your React On Rails app running!
        MSG
        GeneratorMessages.add_info(message)
      end
    end
  end
end

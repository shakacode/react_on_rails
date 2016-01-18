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
      # --skip-js-linters
      class_option :skip_js_linters,
                   type: :boolean,
                   default: false,
                   desc: "Skip installing JavaScript linting files",
                   aliases: "-j"
      # --ruby-linters
      class_option :ruby_linters,
                   type: :boolean,
                   default: false,
                   desc: "Install ruby linting files, tasks, and configs",
                   aliases: "-L"

      # --skip-bootstrap
      class_option :skip_bootstrap,
                   type: :boolean,
                   default: false,
                   desc: "Skip integrating Bootstrap and don't initialize files and regarding configs",
                   aliases: "-b"

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
          /app/assets/javascripts/generated/*
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

          // CRITICAL that generated/vendor-bundle must be BEFORE bootstrap-sprockets and turbolinks
          // since it is exposing jQuery and jQuery-ujs

          //= require generated/vendor-bundle
          //= require generated/app-bundle

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
           config/initializers/react_on_rails.rb
           client/.babelrc
           client/index.jade
           client/server.js
           client/webpack.client.base.config.js
           client/webpack.client.rails.config.js
           REACT_ON_RAILS.md
           client/REACT_ON_RAILS_CLIENT_README.md
           package.json).each { |file| copy_file(base_path + file, file) }
      end

      def template_base_files
        base_path = "base/base/"
        %w(Procfile.dev
           Procfile.dev-hot
           app/views/hello_world/index.html.erb
           client/app/bundles/HelloWorld/components/HelloWorldWidget.jsx
           client/webpack.client.hot.config.js
           client/package.json).each { |file| template(base_path + file + ".tt", file) }
      end

      def add_base_gems_to_gemfile
        return unless options.server_rendering?
        append_to_file("Gemfile", "\ngem 'therubyracer', platforms: :ruby\n")
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

      def template_linter_files_if_appropriate
        return if !options.ruby_linters? && options.skip_js_linters?
        template("base/base/lib/tasks/linters.rake.tt", "lib/tasks/linters.rake")
      end

      def template_assets_rake_file
        template("base/base/lib/tasks/assets.rake.tt", "lib/tasks/assets.rake")
      end

      def append_to_assets_initializer
        data = <<-DATA.strip_heredoc
          # Add client/assets/ folders to asset pipeline's search path.
          # If you do not want to move existing images and fonts from your Rails app
          # you could also consider creating symlinks there that point to the original
          # rails directories. In that case, you would not add these paths here.
          Rails.application.config.assets.paths << Rails.root.join("client", "assets", "stylesheets")
          Rails.application.config.assets.paths << Rails.root.join("client", "assets", "images")
          Rails.application.config.assets.paths << Rails.root.join("client", "assets", "fonts")
          Rails.application.config.assets.precompile += %w( generated/server-bundle.js )
        DATA
        assets_intializer = File.join(destination_root, "config/initializers/assets.rb")
        if File.exist?(assets_intializer)
          append_to_file(assets_intializer, data)
        else
          create_file(assets_intializer, data)
        end
      end

      # rename to application.scss from application.css or application.css.scss
      def force_application_scss_naming_if_necessary
        base_path = "app/assets/stylesheets/"
        application_css = "#{base_path}application.css"
        application_css_scss = "#{base_path}application.css.scss"

        bad_name = dest_file_exists?(application_css) || dest_file_exists?(application_css_scss)
        return unless bad_name

        new_name = File.join(destination_root, "#{base_path}application.scss")
        File.rename(bad_name, new_name)
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

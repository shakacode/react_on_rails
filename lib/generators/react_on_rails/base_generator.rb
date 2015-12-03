require "rails/generators"
require File.expand_path("../generator_helper", __FILE__)
include GeneratorHelper

module ReactOnRails
  module Generators
    class BaseGenerator < Rails::Generators::Base # rubocop:disable Metrics/ClassLength
      hide!
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

        dest_file_exists?(".gitignore") ? append_to_file(".gitignore", data) : puts_setup_file_error(".gitignore", data)
      end

      def update_application_js
        data = <<-DATA.strip_heredoc
          // DO NOT REQUIRE jQuery or jQuery-ujs in this file!
          // DO NOT REQUIRE TREE!

          // CRITICAL that generated/vendor-bundle must be BEFORE bootstrap-sprockets and turbolinks
          // since it is exposing jQuery and jQuery-ujs
          //= require react_on_rails

          //= require generated/vendor-bundle
          //= require generated/app-bundle

          // bootstrap-sprockets depends on generated/vendor-bundle for jQuery.
          //= require bootstrap-sprockets

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
           client/npm-shrinkwrap.json
           client/server.js
           client/webpack.client.hot.config.js
           client/webpack.client.rails.config.js
           lib/tasks/assets.rake
           REACT_ON_RAILS.md
           client/REACT_ON_RAILS_CLIENT_README.md
           package.json).each { |file| copy_file(base_path + file, file) }
      end

      def template_base_files
        base_path = "base/base/"
        %w(Procfile.dev
           app/views/hello_world/index.html.erb
           client/webpack.client.base.config.js
           client/package.json).each { |file| template(base_path + file + ".tt", file) }
      end

      def add_base_gems_to_gemfile
        return unless options.server_rendering?
        append_to_file("Gemfile", "\ngem 'therubyracer', platforms: :ruby\n")
      end

      def template_client_globals_file
        filename = options.server_rendering? ? "clientGlobals.jsx" : "globals.jsx"
        location = "client/app/bundles/HelloWorld/startup"
        template("base/base/#{location}/globals.jsx.tt", "#{location}/#{filename}")
      end

      def install_server_rendering_files_if_enabled
        return unless options.server_rendering?
        base_path = "base/server_rendering/"
        %w(client/webpack.server.rails.config.js
           client/app/bundles/HelloWorld/startup/serverGlobals.jsx).each do |file|
          copy_file(base_path + file, file)
        end
      end

      def template_linter_files_if_appropriate
        return if !options.ruby_linters? && options.skip_js_linters?
        template("base/base/lib/tasks/linters.rake.tt", "lib/tasks/linters.rake")
      end
    end
  end
end

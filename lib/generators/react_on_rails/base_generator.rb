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
                        config/initializers/react_on_rails.rb
                        Procfile.dev
                        Procfile.dev-server]
        base_files.each { |file| copy_file("#{base_path}#{file}", file) }
      end

      def add_base_gems_to_gemfile
        gem "mini_racer", platforms: :ruby
        run "bundle"
      end

      def add_yarn_dependencies
        run "yarn add react-on-rails --exact"
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

      def self.helpful_message
        <<-MSG.strip_heredoc

          What to do next:

            - See the documentation on https://github.com/rails/webpacker/blob/master/docs/webpack.md
              for how to customize the default webpack configuration.

            - Include your webpack assets to your application layout.

                <%= javascript_pack_tag 'hello-world-bundle' %>

            - Run `rails s` to start the Rails server and use Webpacker's default lazy compilation.

            - Visit http://localhost:3000/hello_world and see your React On Rails app running!

            - Run bin/webpack-dev-server to start the Webpack dev server for compilation of Webpack
              assets as soon as you save. This default setup with the dev server does not work
              for server rendering

            - Alternately, you may turn off compile in config/webpacker.yml and run the foreman
              command to start the rails server and run webpack in watch mode.

                foreman start -f Procfile.dev

            - To turn on HMR, edit config/webpacker.yml and set HMR to true. Restart the rails server
              and bin/webpack-dev-server. Or use Procfile.dev-server.

            - To server render, change this line app/views/hello_world/index.html.erb to
              `prerender: true` to see server rendering (right click on page and select "view source").

                <%= react_component("HelloWorldApp", props: @hello_world_props, prerender: true) %>
        MSG
      end

      def print_helpful_message
        GeneratorMessages.add_info(self.class.helpful_message)
      end

      private

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

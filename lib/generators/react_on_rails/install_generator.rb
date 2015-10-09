# Install Generator
# This generator is the only visible generator in the rails generate list and
# should be the only one used.
#
# Usage:
#   rails generate react_on_rails:install [options]
#
# Options:
#   [--with-redux], [--no-with-redux]
#     Indicates when to generate with redux
#   [--with-hello-world-example], [--no-with-hello-world-example]
#     Indicates when to generate with hello world example
#
require "rails/generators"

module ReactOnRails
  module Generators
    class InstallGenerator < Rails::Generators::Base
      # --with-redux
      class_option :with_redux,
                   type: :boolean,
                   default: false,
                   description: "Include Redux package"
      # --with-hello-world-example
      class_option :with_hello_world_example,
                   type: :boolean,
                   default: false,
                   description: "Include a Hello World Example"
      # --with-server-rendering
      class_option :with_server_rendering,
                   type: :boolean,
                   default: false,
                   description: "Include server rendering support"

      def run_generators
        return if check_requirements == false
        if options.with_server_rendering?
          run_with_server_rendering
        else
          run_without_server_rendering
        end
      end

      protected

      def run_without_server_rendering
        if options.with_redux?
          invoke "react_on_rails:install_react_with_redux"
        elsif options.with_hello_world_example?
          invoke "react_on_rails:install_react_with_hello_world"
        else
          invoke "react_on_rails:install_react"
        end
      end

      def run_with_server_rendering
        if options.with_redux?
          invoke "react_on_rails:install_react_with_redux",
                 ["--with-server-rendering"]
        elsif options.with_hello_world_example?
          invoke "react_on_rails:install_react_with_hello_world",
                 ["--with-server-rendering"]
        else
          invoke "react_on_rails:install_react",
                 ["--with-server-rendering"]
        end
      end

      def check_requirements
        # check for node
        if `which node`.blank?
          error = "** nodejs is required. Please install it before continuing."
          error << "https://nodejs.org/en/"
          puts error
        end
        # check for npm
        if `which npm`.blank?
          error = "** npm is required. Please install it before continuing."
          error << "https://www.npmjs.com/"
          puts error
        end
        return false if error
      end
    end
  end
end

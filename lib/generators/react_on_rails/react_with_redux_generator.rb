# frozen_string_literal: true

require "rails/generators"
require_relative "generator_helper"
require_relative "generator_messages"

module ReactOnRails
  module Generators
    class ReactWithReduxGenerator < Rails::Generators::Base
      include GeneratorHelper

      Rails::Generators.hide_namespace(namespace)
      source_root(File.expand_path("templates", __dir__))

      class_option :typescript,
                   type: :boolean,
                   default: false,
                   desc: "Generate TypeScript files",
                   aliases: "-T"

      def create_redux_directories
        # Create auto-bundling directory structure for Redux
        empty_directory("app/javascript/src/HelloWorldApp/ror_components")

        # Create Redux support directories within the component directory
        dirs = %w[actions constants containers reducers store components]
        dirs.each { |name| empty_directory("app/javascript/src/HelloWorldApp/#{name}") }
      end

      def copy_base_files
        base_js_path = "redux/base"
        ext = component_extension(options)

        # Copy Redux-connected component to auto-bundling structure
        copy_file("#{base_js_path}/app/javascript/bundles/HelloWorld/startup/HelloWorldApp.client.#{ext}",
                  "app/javascript/src/HelloWorldApp/ror_components/HelloWorldApp.client.#{ext}")
        copy_file("#{base_js_path}/app/javascript/bundles/HelloWorld/startup/HelloWorldApp.server.#{ext}",
                  "app/javascript/src/HelloWorldApp/ror_components/HelloWorldApp.server.#{ext}")
        copy_file("#{base_js_path}/app/javascript/bundles/HelloWorld/components/HelloWorld.module.css",
                  "app/javascript/src/HelloWorldApp/components/HelloWorld.module.css")

        # Update import paths in client component
        ror_client_file = "app/javascript/src/HelloWorldApp/ror_components/HelloWorldApp.client.#{ext}"
        gsub_file(ror_client_file, "../store/helloWorldStore", "../store/helloWorldStore")
        gsub_file(ror_client_file, "../containers/HelloWorldContainer",
                  "../containers/HelloWorldContainer")
      end

      def copy_base_redux_files
        base_hello_world_path = "redux/base/app/javascript/bundles/HelloWorld"
        redux_extension = options.typescript? ? "ts" : "js"

        # Copy Redux infrastructure files with appropriate extension
        %W[actions/helloWorldActionCreators.#{redux_extension}
           containers/HelloWorldContainer.#{redux_extension}
           constants/helloWorldConstants.#{redux_extension}
           reducers/helloWorldReducer.#{redux_extension}
           store/helloWorldStore.#{redux_extension}
           components/HelloWorld.#{component_extension(options)}].each do |file|
             copy_file("#{base_hello_world_path}/#{file}",
                       "app/javascript/src/HelloWorldApp/#{file}")
           end
      end

      def create_appropriate_templates
        base_path = "base/base"
        config = {
          component_name: "HelloWorldApp"
        }

        # Only create the view template - no manual bundle needed for auto-bundling
        template("#{base_path}/app/views/hello_world/index.html.erb.tt",
                 "app/views/hello_world/index.html.erb", config)
      end

      def add_redux_npm_dependencies
        # Add Redux dependencies as regular dependencies
        regular_packages = %w[redux react-redux]

        # Try using GeneratorHelper first (package manager agnostic)
        success = add_npm_dependencies(regular_packages)

        # Fallback to package manager detection if GeneratorHelper fails
        return if success

        package_manager = GeneratorMessages.detect_package_manager
        return unless package_manager

        install_packages_with_fallback(regular_packages, dev: false, package_manager: package_manager)
      end

      def add_redux_specific_messages
        # Append Redux-specific post-install instructions
        GeneratorMessages.add_info(
          GeneratorMessages.helpful_message_after_installation(component_name: "HelloWorldApp", route: "hello_world")
        )
      end

      private

      def install_packages_with_fallback(packages, dev:, package_manager:)
        install_args = build_install_args(package_manager, dev, packages)

        success = system(*install_args)
        return if success

        install_command = install_args.join(" ")
        warning = <<~MSG.strip
          ⚠️  Failed to install Redux dependencies automatically.

          Please run manually:
              #{install_command}
        MSG
        GeneratorMessages.add_warning(warning)
      end

      def build_install_args(package_manager, dev, packages)
        # Security: Validate package manager to prevent command injection
        allowed_package_managers = %w[npm yarn pnpm bun].freeze
        unless allowed_package_managers.include?(package_manager)
          raise ArgumentError, "Invalid package manager: #{package_manager}"
        end

        base_commands = {
          "npm" => %w[npm install],
          "yarn" => %w[yarn add],
          "pnpm" => %w[pnpm add],
          "bun" => %w[bun add]
        }

        base_args = base_commands[package_manager].dup
        base_args << dev_flag_for(package_manager) if dev
        base_args + packages
      end

      def dev_flag_for(package_manager)
        case package_manager
        when "npm", "pnpm" then "--save-dev"
        when "yarn", "bun" then "--dev"
        end
      end
    end
  end
end

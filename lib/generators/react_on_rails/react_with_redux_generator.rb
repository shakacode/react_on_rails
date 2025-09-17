# frozen_string_literal: true

require "rails/generators"
require_relative "generator_helper"

module ReactOnRails
  module Generators
    class ReactWithReduxGenerator < Rails::Generators::Base
      include GeneratorHelper

      Rails::Generators.hide_namespace(namespace)
      source_root(File.expand_path("templates", __dir__))

      class_option :typescript,
                   type: :boolean,
                   default: false,
                   desc: "Generate TypeScript files"

      def create_redux_directories
        # Create auto-registration directory structure for Redux
        empty_directory("app/javascript/src/HelloWorldApp/ror_components")

        # Create Redux support directories within the component directory
        dirs = %w[actions constants containers reducers store components]
        dirs.each { |name| empty_directory("app/javascript/src/HelloWorldApp/#{name}") }
      end

      def copy_base_files
        base_js_path = "redux/base"
        extension = options.typescript? ? "tsx" : "jsx"

        # Copy Redux-connected component to auto-registration structure
        copy_file("#{base_js_path}/app/javascript/bundles/HelloWorld/startup/HelloWorldApp.client.#{extension}",
                  "app/javascript/src/HelloWorldApp/ror_components/HelloWorldApp.client.#{extension}")
        copy_file("#{base_js_path}/app/javascript/bundles/HelloWorld/startup/HelloWorldApp.server.#{extension}",
                  "app/javascript/src/HelloWorldApp/ror_components/HelloWorldApp.server.#{extension}")
        copy_file("#{base_js_path}/app/javascript/bundles/HelloWorld/components/HelloWorld.module.css",
                  "app/javascript/src/HelloWorldApp/components/HelloWorld.module.css")

        # Update import paths in client component
        ror_client_file = "app/javascript/src/HelloWorldApp/ror_components/HelloWorldApp.client.#{extension}"
        gsub_file(ror_client_file, "../store/helloWorldStore", "../store/helloWorldStore")
        gsub_file(ror_client_file, "../containers/HelloWorldContainer",
                  "../containers/HelloWorldContainer")
      end

      def copy_base_redux_files
        base_hello_world_path = "redux/base/app/javascript/bundles/HelloWorld"
        component_extension = options.typescript? ? "tsx" : "jsx"
        redux_extension = options.typescript? ? "ts" : "js"

        # Copy Redux infrastructure files with appropriate extension
        %w[actions/helloWorldActionCreators
           containers/HelloWorldContainer
           constants/helloWorldConstants
           reducers/helloWorldReducer
           store/helloWorldStore].each do |file|
             copy_file("#{base_hello_world_path}/#{file}.#{redux_extension}",
                       "app/javascript/src/HelloWorldApp/#{file}.#{redux_extension}")
           end

        # Copy component file with appropriate extension
        copy_file("#{base_hello_world_path}/components/HelloWorld.#{component_extension}",
                  "app/javascript/src/HelloWorldApp/components/HelloWorld.#{component_extension}")
      end

      def create_appropriate_templates
        base_path = "base/base"
        config = {
          component_name: "HelloWorldApp"
        }

        # Only create the view template - no manual bundle needed for auto registration
        template("#{base_path}/app/views/hello_world/index.html.erb.tt",
                 "app/views/hello_world/index.html.erb", config)
      end

      def add_redux_npm_dependencies
        # Add Redux dependencies as regular dependencies
        regular_packages = %w[redux react-redux]

        # Try using GeneratorHelper first (package manager agnostic)
        success = add_npm_dependencies(regular_packages)

        # Add TypeScript types as dev dependency if TypeScript is enabled
        if options.typescript?
          types_success = add_npm_dependencies(%w[@types/react-redux], dev: true)
          success &&= types_success
        end

        # Fallback to package manager detection if GeneratorHelper fails
        return if success

        package_manager = detect_package_manager
        return unless package_manager

        install_packages_with_fallback(regular_packages, dev: false, package_manager: package_manager)

        return unless options.typescript?

        install_packages_with_fallback(%w[@types/react-redux], dev: true, package_manager: package_manager)
      end

      private

      def install_packages_with_fallback(packages, dev:, package_manager:)
        packages_str = packages.join(" ")
        install_command = build_install_command(package_manager, dev, packages_str)

        success = system(install_command)
        return if success

        warning = <<~MSG.strip
          ⚠️  Failed to install Redux dependencies automatically.

          Please run manually:
              #{install_command}
        MSG
        GeneratorMessages.add_warning(warning)
      end

      def build_install_command(package_manager, dev, packages_str)
        commands = {
          "npm" => { dev: "npm install --save-dev", prod: "npm install" },
          "yarn" => { dev: "yarn add --dev", prod: "yarn add" },
          "pnpm" => { dev: "pnpm add --save-dev", prod: "pnpm add" },
          "bun" => { dev: "bun add --dev", prod: "bun add" }
        }

        command_type = dev ? :dev : :prod
        "#{commands[package_manager][command_type]} #{packages_str}"
      end

      def add_redux_specific_messages
        # Override the generic messages with Redux-specific instructions
        require_relative "generator_messages"
        GeneratorMessages.output.clear
        GeneratorMessages.add_info(
          GeneratorMessages.helpful_message_after_installation(component_name: "HelloWorldApp")
        )
      end
    end
  end
end

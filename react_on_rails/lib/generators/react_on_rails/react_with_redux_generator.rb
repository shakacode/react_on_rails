# frozen_string_literal: true

require "rails/generators"
require_relative "generator_helper"
require_relative "generator_messages"
require_relative "demo_page_config"

module ReactOnRails
  module Generators
    class ReactWithReduxGenerator < Rails::Generators::Base
      include GeneratorHelper
      include DemoPageConfig

      Rails::Generators.hide_namespace(namespace)
      source_root(File.expand_path("templates", __dir__))
      LEGACY_REDUX_GENERATOR_WARNING = <<~MSG.strip.freeze
        The react_on_rails:react_with_redux generator is a hidden legacy Redux generator path and is not
        recommended for new React on Rails apps.
        New apps should use the default React on Rails installer without Redux. Runtime Redux APIs such as
        redux_store remain supported.
      MSG

      class_option :typescript, type: :boolean, default: false, desc: "Generate TypeScript files", aliases: "-T"
      class_option :invoked_by_install, type: :boolean, default: false, hide: true
      class_option :new_app, type: :boolean, default: false, hide: true
      class_option :rsc, type: :boolean, default: false, hide: true
      class_option :tailwind, type: :boolean, default: false, hide: true

      def run_generator
        validate_standalone_tailwind
        create_redux_directories
        copy_base_files
        copy_base_redux_files
        create_appropriate_templates
        add_redux_npm_dependencies
        add_redux_specific_messages
      ensure
        print_generator_messages unless options.invoked_by_install?
      end

      private

      def validate_standalone_tailwind
        return unless unsupported_standalone_tailwind?

        raise Thor::Error,
              "The standalone react_on_rails:react_with_redux generator does not support --tailwind"
      end

      def create_redux_directories
        component_dir = example_component_source_directory("HelloWorldApp")

        # Create auto-bundling directory structure for Redux
        empty_directory("#{component_dir}/ror_components")

        # Create Redux support directories within the component directory
        dirs = %w[actions constants containers reducers store components]
        dirs.each { |name| empty_directory("#{component_dir}/#{name}") }
      end

      def copy_base_files
        base_js_path = "redux/base"
        ext = component_extension(options)
        component_dir = example_component_source_directory("HelloWorldApp")

        # Copy Redux-connected component to auto-bundling structure
        copy_file("#{base_js_path}/app/javascript/bundles/HelloWorld/startup/HelloWorldApp.client.#{ext}",
                  "#{component_dir}/ror_components/HelloWorldApp.client.#{ext}")
        copy_file("#{base_js_path}/app/javascript/bundles/HelloWorld/startup/HelloWorldApp.server.#{ext}",
                  "#{component_dir}/ror_components/HelloWorldApp.server.#{ext}")

        return if use_tailwind?

        copy_file("#{base_js_path}/app/javascript/bundles/HelloWorld/components/HelloWorld.module.css",
                  "#{component_dir}/components/HelloWorld.module.css")
      end

      def copy_base_redux_files
        base_hello_world_path = "redux/base/app/javascript/bundles/HelloWorld"
        tailwind_hello_world_path = "redux/tailwind/app/javascript/bundles/HelloWorld"
        redux_extension = options.typescript? ? "ts" : "js"
        component_dir = example_component_source_directory("HelloWorldApp")

        # Copy Redux infrastructure files with appropriate extension
        %W[actions/helloWorldActionCreators.#{redux_extension}
           containers/HelloWorldContainer.#{redux_extension}
           constants/helloWorldConstants.#{redux_extension}
           reducers/helloWorldReducer.#{redux_extension}
           store/helloWorldStore.#{redux_extension}].each do |file|
             copy_file("#{base_hello_world_path}/#{file}",
                       "#{component_dir}/#{file}")
           end

        component_file = "components/HelloWorld.#{component_extension(options)}"
        component_source_path = use_tailwind? ? tailwind_hello_world_path : base_hello_world_path
        copy_file("#{component_source_path}/#{component_file}",
                  "#{component_dir}/#{component_file}")
      end

      def create_appropriate_templates
        base_path = "base/base"

        # Only create the view template - no manual bundle needed for auto-bundling
        template("#{base_path}/app/views/hello_world/index.html.erb.tt",
                 "app/views/hello_world/index.html.erb",
                 build_hello_world_view_config(
                   component_name: "HelloWorldApp",
                   source_path: example_component_source_path("HelloWorldApp"),
                   landing_page: new_app_landing_page_available?,
                   redux: true,
                   rsc_demo: options[:rsc]
                 ))
      end

      def add_redux_npm_dependencies
        # Add Redux dependencies as regular dependencies
        regular_packages = %w[redux react-redux]

        # Try using GeneratorHelper first (package manager agnostic)
        success = add_npm_dependencies(regular_packages)

        # Fallback to package manager detection if GeneratorHelper fails
        return if success

        package_manager = GeneratorMessages.detect_package_manager(app_root: destination_root)
        return unless package_manager

        install_packages_with_fallback(regular_packages, dev: false, package_manager:)
      end

      def add_redux_specific_messages
        return if options.invoked_by_install?

        GeneratorMessages.add_warning(LEGACY_REDUX_GENERATOR_WARNING)
        GeneratorMessages.add_info(
          GeneratorMessages.helpful_message_after_installation(component_name: "HelloWorldApp", route: "hello_world",
                                                               pro: Gem.loaded_specs.key?("react_on_rails_pro"),
                                                               tailwind: use_tailwind?,
                                                               app_root: destination_root)
        )
      end

      def unsupported_standalone_tailwind?
        return false unless use_tailwind?
        return false if options.invoked_by_install?

        GeneratorMessages.add_error(<<~MSG.strip)
          🚫 The standalone react_on_rails:react_with_redux generator does not support --tailwind.

          Tailwind setup requires the base React on Rails installer so it can create the
          react_on_rails_tailwind pack, stylesheet, dependencies, and webpack/Rspack config.

          Use the hidden legacy installer path if you intentionally need the Redux scaffold with Tailwind:

            rails generate react_on_rails:install --redux --tailwind

          For new apps, run the default installer without Redux:

            rails generate react_on_rails:install --tailwind
        MSG
        true
      end

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

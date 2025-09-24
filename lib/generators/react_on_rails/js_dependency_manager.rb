# frozen_string_literal: true

require_relative "generator_messages"

module ReactOnRails
  module Generators
    # Shared module for managing JavaScript dependencies across generators
    # This module provides common functionality for adding and installing
    # JS dependencies to avoid code duplication between generators.
    module JsDependencyManager
      private

      def setup_js_dependencies
        @added_dependencies_to_package_json ||= false
        @ran_direct_installs ||= false
        add_js_dependencies
        install_js_dependencies if @added_dependencies_to_package_json && !@ran_direct_installs
      end

      def add_js_dependencies
        add_react_on_rails_package
        add_react_dependencies
        add_css_dependencies
        add_dev_dependencies
      end

      def add_react_on_rails_package
        major_minor_patch_only = /\A\d+\.\d+\.\d+\z/

        # Try to use package_json gem first, fall back to direct npm commands
        react_on_rails_pkg = if ReactOnRails::VERSION.match?(major_minor_patch_only)
                               ["react-on-rails@#{ReactOnRails::VERSION}"]
                             else
                               puts "Adding the latest react-on-rails NPM module. " \
                                    "Double check this is correct in package.json"
                               ["react-on-rails"]
                             end

        puts "Installing React on Rails package..."
        if add_npm_dependencies(react_on_rails_pkg)
          @added_dependencies_to_package_json = true
          return
        end

        puts "Using direct npm commands as fallback"
        success = system("npm", "install", *react_on_rails_pkg)
        @ran_direct_installs = true if success
        handle_npm_failure("react-on-rails package", react_on_rails_pkg) unless success
      end

      def add_react_dependencies
        puts "Installing React dependencies..."
        react_deps = %w[
          react
          react-dom
          @babel/preset-react
          prop-types
          babel-plugin-transform-react-remove-prop-types
          babel-plugin-macros
        ]
        if add_npm_dependencies(react_deps)
          @added_dependencies_to_package_json = true
          return
        end

        success = system("npm", "install", *react_deps)
        @ran_direct_installs = true if success
        handle_npm_failure("React dependencies", react_deps) unless success
      end

      def add_css_dependencies
        puts "Installing CSS handling dependencies..."
        css_deps = %w[
          css-loader
          css-minimizer-webpack-plugin
          mini-css-extract-plugin
          style-loader
        ]
        if add_npm_dependencies(css_deps)
          @added_dependencies_to_package_json = true
          return
        end

        success = system("npm", "install", *css_deps)
        @ran_direct_installs = true if success
        handle_npm_failure("CSS dependencies", css_deps) unless success
      end

      def add_dev_dependencies
        puts "Installing development dependencies..."
        dev_deps = %w[
          @pmmmwh/react-refresh-webpack-plugin
          react-refresh
        ]
        if add_npm_dependencies(dev_deps, dev: true)
          @added_dependencies_to_package_json = true
          return
        end

        success = system("npm", "install", "--save-dev", *dev_deps)
        @ran_direct_installs = true if success
        handle_npm_failure("development dependencies", dev_deps, dev: true) unless success
      end

      def install_js_dependencies
        # Detect which package manager to use
        success = if File.exist?(File.join(destination_root, "yarn.lock"))
                    system("yarn", "install")
                  elsif File.exist?(File.join(destination_root, "pnpm-lock.yaml"))
                    system("pnpm", "install")
                  elsif File.exist?(File.join(destination_root, "package-lock.json")) ||
                        File.exist?(File.join(destination_root, "package.json"))
                    # Use npm for package-lock.json or as default fallback
                    system("npm", "install")
                  else
                    true # No package manager detected, skip
                  end

        unless success
          GeneratorMessages.add_warning(<<~MSG.strip)
            ⚠️  JavaScript dependencies installation failed.

            This could be due to network issues or missing package manager.
            You can install dependencies manually later by running:
            • npm install (if using npm)
            • yarn install (if using yarn)
            • pnpm install (if using pnpm)
          MSG
        end

        success
      end

      def handle_npm_failure(dependency_type, packages, dev: false)
        install_command = dev ? "npm install --save-dev" : "npm install"
        GeneratorMessages.add_warning(<<~MSG.strip)
          ⚠️  Failed to install #{dependency_type}.

          The following packages could not be installed automatically:
          #{packages.map { |pkg| "  • #{pkg}" }.join("\n")}

          This could be due to network issues or missing package manager.
          You can install them manually later by running:
            #{install_command} #{packages.join(' ')}
        MSG
      end
    end
  end
end

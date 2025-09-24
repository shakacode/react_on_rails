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
        # Only run final install if package_json gem was used and no direct installs ran
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

        react_on_rails_pkg = if ReactOnRails::VERSION.match?(major_minor_patch_only)
                               "react-on-rails@#{ReactOnRails::VERSION}"
                             else
                               puts "Adding the latest react-on-rails NPM module. " \
                                    "Double check this is correct in package.json"
                               "react-on-rails"
                             end

        puts "Installing React on Rails package..."
        if add_js_dependency(react_on_rails_pkg)
          @added_dependencies_to_package_json = true
        else
          # Fallback to direct npm install
          puts "Using direct npm commands as fallback"
          success = system("npm", "install", react_on_rails_pkg)
          @ran_direct_installs = true if success
          handle_npm_failure("react-on-rails package", [react_on_rails_pkg]) unless success
        end
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

        if add_js_dependencies_batch(react_deps)
          @added_dependencies_to_package_json = true
        else
          # Fallback to direct npm install
          success = system("npm", "install", *react_deps)
          @ran_direct_installs = true if success
          handle_npm_failure("React dependencies", react_deps) unless success
        end
      end

      def add_css_dependencies
        puts "Installing CSS handling dependencies..."
        css_deps = %w[
          css-loader
          css-minimizer-webpack-plugin
          mini-css-extract-plugin
          style-loader
        ]

        if add_js_dependencies_batch(css_deps)
          @added_dependencies_to_package_json = true
        else
          # Fallback to direct npm install
          success = system("npm", "install", *css_deps)
          @ran_direct_installs = true if success
          handle_npm_failure("CSS dependencies", css_deps) unless success
        end
      end

      def add_dev_dependencies
        puts "Installing development dependencies..."
        dev_deps = %w[
          @pmmmwh/react-refresh-webpack-plugin
          react-refresh
        ]

        if add_js_dependencies_batch(dev_deps, dev: true)
          @added_dependencies_to_package_json = true
        else
          # Fallback to direct npm install
          success = system("npm", "install", "--save-dev", *dev_deps)
          @ran_direct_installs = true if success
          handle_npm_failure("development dependencies", dev_deps, dev: true) unless success
        end
      end

      # Add a single dependency using package_json gem
      def add_js_dependency(package, dev: false)
        return false unless package_json_available?

        pj = package_json
        return false unless pj

        begin
          if dev
            pj.manager.add(package, type: :dev)
          else
            pj.manager.add(package)
          end
          true
        rescue StandardError => e
          puts "Warning: Could not add #{package} via package_json gem: #{e.message}"
          false
        end
      end

      # Add multiple dependencies at once using package_json gem
      def add_js_dependencies_batch(packages, dev: false)
        return false unless package_json_available?

        # Use the add_npm_dependencies helper from GeneratorHelper
        add_npm_dependencies(packages, dev: dev)
      end

      # Check if package_json gem is available and loaded
      def package_json_available?
        # Check if Shakapacker or package_json gem is available
        return true if defined?(PackageJson)

        begin
          require "package_json"
          true
        rescue LoadError
          false
        end
      end

      def install_js_dependencies
        # First try to use package_json gem's install method if available
        if package_json_available? && package_json
          begin
            package_json.manager.install
            return true
          rescue StandardError => e
            puts "Warning: package_json gem install failed: #{e.message}"
            # Fall through to manual detection
          end
        end

        # Fallback to detecting package manager and running install
        success = detect_and_run_package_manager_install

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

      def detect_and_run_package_manager_install
        # Detect which package manager to use based on lock files
        if File.exist?(File.join(destination_root, "yarn.lock"))
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

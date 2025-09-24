# frozen_string_literal: true

require_relative "generator_messages"

module ReactOnRails
  module Generators
    # Shared module for managing JavaScript dependencies across generators
    # This module provides common functionality for adding and installing
    # JS dependencies to avoid code duplication between generators.
    #
    # Since react_on_rails requires shakapacker, and shakapacker includes
    # package_json as a dependency, the package_json gem is always available.
    #
    # == Required Instance Variables
    # Including classes must support these instance variables:
    # - @added_dependencies_to_package_json: Boolean tracking if package_json gem was used
    #
    # == Required Methods
    # Including classes must include GeneratorHelper module which provides:
    # - add_npm_dependencies(packages, dev: false): Add packages via package_json gem
    # - package_json: Access to PackageJson instance (always available via shakapacker)
    # - destination_root: Generator destination directory
    #
    # == Usage
    # Include this module in generator classes and call setup_js_dependencies
    # to handle all JS dependency installation via package_json gem.
    module JsDependencyManager
      # Core React dependencies required for React on Rails
      REACT_DEPENDENCIES = %w[
        react
        react-dom
        @babel/preset-react
        prop-types
        babel-plugin-transform-react-remove-prop-types
        babel-plugin-macros
      ].freeze

      # CSS processing dependencies for webpack
      CSS_DEPENDENCIES = %w[
        css-loader
        css-minimizer-webpack-plugin
        mini-css-extract-plugin
        style-loader
      ].freeze

      # Development-only dependencies for hot reloading
      DEV_DEPENDENCIES = %w[
        @pmmmwh/react-refresh-webpack-plugin
        react-refresh
      ].freeze

      private

      def setup_js_dependencies
        @added_dependencies_to_package_json ||= false
        add_js_dependencies
        install_js_dependencies
      end

      def add_js_dependencies
        add_react_on_rails_package
        add_react_dependencies
        add_css_dependencies
        add_dev_dependencies
      end

      def add_react_on_rails_package
        # Always use exact version match between gem and npm package
        react_on_rails_pkg = "react-on-rails@#{ReactOnRails::VERSION}"

        puts "Installing React on Rails package..."
        if add_js_dependency(react_on_rails_pkg)
          @added_dependencies_to_package_json = true
        else
          # This should not happen since package_json is always available via shakapacker
          raise "Failed to add react-on-rails package via package_json gem"
        end
      end

      def add_react_dependencies
        puts "Installing React dependencies..."

        if add_js_dependencies_batch(REACT_DEPENDENCIES)
          @added_dependencies_to_package_json = true
        else
          # This should not happen since package_json is always available via shakapacker
          raise "Failed to add React dependencies via package_json gem"
        end
      end

      def add_css_dependencies
        puts "Installing CSS handling dependencies..."

        if add_js_dependencies_batch(CSS_DEPENDENCIES)
          @added_dependencies_to_package_json = true
        else
          # This should not happen since package_json is always available via shakapacker
          raise "Failed to add CSS dependencies via package_json gem"
        end
      end

      def add_dev_dependencies
        puts "Installing development dependencies..."

        if add_js_dependencies_batch(DEV_DEPENDENCIES, dev: true)
          @added_dependencies_to_package_json = true
        else
          # This should not happen since package_json is always available via shakapacker
          raise "Failed to add development dependencies via package_json gem"
        end
      end

      # Add a single dependency using package_json gem
      def add_js_dependency(package, dev: false)
        pj = package_json
        return false unless pj

        begin
          # Ensure package is in array format for package_json gem
          packages_array = [package]
          if dev
            pj.manager.add(packages_array, type: :dev)
          else
            pj.manager.add(packages_array)
          end
          true
        rescue StandardError => e
          puts "Warning: Could not add #{package} via package_json gem: #{e.message}"
          false
        end
      end

      # Add multiple dependencies at once using package_json gem
      def add_js_dependencies_batch(packages, dev: false)
        # Use the add_npm_dependencies helper from GeneratorHelper
        add_npm_dependencies(packages, dev: dev)
      end

      def install_js_dependencies
        # Use package_json gem's install method (always available via shakapacker)
        begin
          package_json.manager.install
          true
        rescue StandardError => e
          GeneratorMessages.add_warning(<<~MSG.strip)
            ⚠️  JavaScript dependencies installation failed: #{e.message}

            This could be due to network issues or package manager problems.
            You can install dependencies manually later by running:
            • npm install (if using npm)
            • yarn install (if using yarn)
            • pnpm install (if using pnpm)
          MSG
          false
        end
      end

      # No longer needed since package_json gem handles package manager detection
    end
  end
end

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
    # == Instance Variables
    # The module initializes and manages these instance variables:
    # - @added_dependencies_to_package_json: Boolean tracking if package_json gem was used
    #   (initialized by setup_js_dependencies using `unless defined?` pattern)
    #
    # == Required Methods
    # Including classes must include GeneratorHelper module which provides:
    # - add_npm_dependencies(packages, dev: false): Add packages via package_json gem
    # - package_json: Access to PackageJson instance (always available via shakapacker)
    # - destination_root: Generator destination directory
    #
    # == Optional Methods
    # Including classes may define:
    # - options.rspack?: Returns true if --rspack flag is set (for Rspack support)
    # - options.typescript?: Returns true if --typescript flag is set (for TypeScript support)
    #
    # == Installation Behavior
    # The module ALWAYS runs package manager install after adding dependencies.
    # This is safe because package_json gem's install is idempotent - it only
    # installs what's actually needed from package.json. This prevents edge cases
    # where package.json was modified but dependencies weren't installed.
    #
    # == Usage
    # Include this module in generator classes and call setup_js_dependencies
    # to handle all JS dependency installation via package_json gem.
    module JsDependencyManager
      # Core React dependencies required for React on Rails
      # Note: @babel/preset-react and babel plugins are NOT included here because:
      # - Shakapacker handles JavaScript transpiler configuration (babel, swc, or esbuild)
      # - Users configure their preferred transpiler via shakapacker.yml javascript_transpiler setting
      # - SWC is now the default and doesn't need Babel presets
      # - For Babel users, shakapacker will install babel-loader and its dependencies
      REACT_DEPENDENCIES = %w[
        react
        react-dom
        prop-types
      ].freeze

      # CSS processing dependencies for webpack
      CSS_DEPENDENCIES = %w[
        css-loader
        css-minimizer-webpack-plugin
        mini-css-extract-plugin
        style-loader
      ].freeze

      # Development-only dependencies for hot reloading (Webpack)
      DEV_DEPENDENCIES = %w[
        @pmmmwh/react-refresh-webpack-plugin
        react-refresh
      ].freeze

      # Rspack core dependencies (only installed when --rspack flag is used)
      RSPACK_DEPENDENCIES = %w[
        @rspack/core
        rspack-manifest-plugin
      ].freeze

      # Rspack development dependencies for hot reloading
      RSPACK_DEV_DEPENDENCIES = %w[
        @rspack/cli
        @rspack/plugin-react-refresh
        react-refresh
      ].freeze

      # TypeScript dependencies (only installed when --typescript flag is used)
      # Note: @babel/preset-typescript is NOT included because:
      # - SWC is now the default javascript_transpiler (has built-in TypeScript support)
      # - Shakapacker handles the transpiler configuration via shakapacker.yml
      # - If users choose javascript_transpiler: 'babel', they should manually add @babel/preset-typescript
      #   and configure it in their babel.config.js
      TYPESCRIPT_DEPENDENCIES = %w[
        typescript
        @types/react
        @types/react-dom
      ].freeze

      private

      def setup_js_dependencies
        # Initialize instance variable if not already defined by including class
        # This ensures safe operation when the module is first included
        @added_dependencies_to_package_json = false unless defined?(@added_dependencies_to_package_json)
        add_js_dependencies

        # Always run install to ensure all dependencies are properly installed.
        # The package_json gem's install method is idempotent and safe to call
        # even if packages were already added - it will only install what's needed.
        # This ensures edge cases where package.json was modified but install wasn't
        # run are handled correctly.
        install_js_dependencies
      end

      def add_js_dependencies
        add_react_on_rails_package
        add_react_dependencies
        add_css_dependencies
        # Rspack dependencies are only added when --rspack flag is used
        add_rspack_dependencies if respond_to?(:options) && options.rspack?
        # Dev dependencies vary based on bundler choice
        add_dev_dependencies
      end

      def add_react_on_rails_package
        # Use exact version match between gem and npm package for stable releases
        # For pre-release versions (e.g., 16.1.0-rc.1), use latest to avoid installing
        # a version that may not exist in the npm registry
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
          # This should not happen since package_json is always available via shakapacker
          raise "Failed to add react-on-rails package via package_json gem. " \
                "This indicates shakapacker dependency may not be properly installed."
        end
      end

      def add_react_dependencies
        puts "Installing React dependencies..."

        if add_js_dependencies_batch(REACT_DEPENDENCIES)
          @added_dependencies_to_package_json = true
        else
          # This should not happen since package_json is always available via shakapacker
          raise "Failed to add React dependencies (#{REACT_DEPENDENCIES.join(', ')}) via package_json gem. " \
                "This indicates shakapacker dependency may not be properly installed."
        end
      end

      def add_css_dependencies
        puts "Installing CSS handling dependencies..."

        if add_js_dependencies_batch(CSS_DEPENDENCIES)
          @added_dependencies_to_package_json = true
        else
          # This should not happen since package_json is always available via shakapacker
          raise "Failed to add CSS dependencies (#{CSS_DEPENDENCIES.join(', ')}) via package_json gem. " \
                "This indicates shakapacker dependency may not be properly installed."
        end
      end

      def add_rspack_dependencies
        puts "Installing Rspack core dependencies..."

        if add_js_dependencies_batch(RSPACK_DEPENDENCIES)
          @added_dependencies_to_package_json = true
        else
          # This should not happen since package_json is always available via shakapacker
          raise "Failed to add Rspack dependencies (#{RSPACK_DEPENDENCIES.join(', ')}) via package_json gem. " \
                "This indicates shakapacker dependency may not be properly installed."
        end
      end

      def add_typescript_dependencies
        puts "Installing TypeScript dependencies..."

        if add_js_dependencies_batch(TYPESCRIPT_DEPENDENCIES, dev: true)
          @added_dependencies_to_package_json = true
        else
          # This should not happen since package_json is always available via shakapacker
          raise "Failed to add TypeScript dependencies (#{TYPESCRIPT_DEPENDENCIES.join(', ')}) via package_json gem. " \
                "This indicates shakapacker dependency may not be properly installed."
        end
      end

      def add_dev_dependencies
        puts "Installing development dependencies..."

        # Use Rspack-specific dev dependencies if --rspack flag is set
        dev_deps = if respond_to?(:options) && options.rspack?
                     RSPACK_DEV_DEPENDENCIES
                   else
                     DEV_DEPENDENCIES
                   end

        if add_js_dependencies_batch(dev_deps, dev: true)
          @added_dependencies_to_package_json = true
        else
          # This should not happen since package_json is always available via shakapacker
          raise "Failed to add development dependencies (#{dev_deps.join(', ')}) via package_json gem. " \
                "This indicates shakapacker dependency may not be properly installed."
        end
      end

      # Add a single dependency using package_json gem
      #
      # This method is used internally for adding the react-on-rails package
      # with version-specific handling (react-on-rails@VERSION).
      # For batch operations, use add_js_dependencies_batch instead.
      #
      # @param package [String] Package specifier (e.g., "react-on-rails@16.0.0")
      # @param dev [Boolean] Whether to add as dev dependency
      # @return [Boolean] true if successful, false otherwise
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
      #
      # This method delegates to GeneratorHelper's add_npm_dependencies for
      # better package manager abstraction and batch processing efficiency.
      #
      # @param packages [Array<String>] Package names to add
      # @param dev [Boolean] Whether to add as dev dependencies
      # @return [Boolean] true if successful, false otherwise
      def add_js_dependencies_batch(packages, dev: false)
        # Use the add_npm_dependencies helper from GeneratorHelper
        add_npm_dependencies(packages, dev: dev)
      end

      def install_js_dependencies
        # Use package_json gem's install method (always available via shakapacker)
        # package_json is guaranteed to be available because:
        # 1. react_on_rails gemspec requires shakapacker
        # 2. shakapacker gemspec requires package_json
        # 3. GeneratorHelper provides package_json method
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

      # No longer needed since package_json gem handles package manager detection
    end
  end
end

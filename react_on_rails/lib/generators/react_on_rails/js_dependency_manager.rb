# frozen_string_literal: true

require_relative "generator_messages"

# rubocop:disable Metrics/ModuleLength
module ReactOnRails
  module Generators
    # Shared module for managing JavaScript dependencies across generators
    # This module provides common functionality for adding and installing
    # JS dependencies to avoid code duplication between generators.
    #
    # Since react_on_rails requires shakapacker, and shakapacker includes
    # package_json as a dependency, the package_json gem is always available.
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
    # This is safe because package_json gem's install method is idempotent - it only
    # installs what's actually needed from package.json. This prevents edge cases
    # where package.json was modified but dependencies weren't installed.
    #
    # == Error Handling Philosophy
    # All dependency addition methods use a graceful degradation approach:
    # - Methods return false on failure instead of raising exceptions
    # - StandardError is caught at the lowest level (add_package) and higher levels (add_*_dependencies)
    # - Failures trigger user-facing warnings via GeneratorMessages
    # - Warnings provide clear manual installation instructions
    #
    # This ensures the generator ALWAYS completes successfully, even when:
    # - Network connectivity issues prevent package downloads
    # - Package manager (npm/yarn/pnpm) has permission errors
    # - package_json gem encounters unexpected states
    #
    # Users can manually run package installation commands after generator completion.
    # This is preferable to generator crashes that leave Rails apps in incomplete states.
    #
    # == Usage
    # Include this module in generator classes and call setup_js_dependencies
    # to handle all JS dependency installation via package_json gem.
    module JsDependencyManager
      # Core React dependencies required for React on Rails
      # Note: @babel/preset-react is handled separately in BABEL_REACT_DEPENDENCIES
      # and is added only when SWC is not the active transpiler.
      REACT_DEPENDENCIES = %w[
        react
        react-dom
        prop-types
      ].freeze

      # Babel preset needed by the generated babel.config.js for non-SWC setups.
      BABEL_REACT_DEPENDENCIES = %w[
        @babel/preset-react
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

      # SWC transpiler dependencies (for Shakapacker 9.3.0+ default transpiler)
      # SWC is ~20x faster than Babel and is the default for new Shakapacker installations
      SWC_DEPENDENCIES = %w[
        @swc/core
        swc-loader
      ].freeze

      private

      def setup_js_dependencies
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
        add_rspack_dependencies if respond_to?(:options) && options&.rspack?
        # SWC dependencies are only added when SWC is the configured transpiler
        if using_swc?
          add_swc_dependencies
        else
          add_babel_react_dependencies
        end
        # Dev dependencies vary based on bundler choice
        add_dev_dependencies
      end

      def add_react_on_rails_package
        # Use exact version match between gem and npm package for all versions including pre-releases
        # Ruby gem versions use dots (16.2.0.beta.10) but npm requires hyphens (16.2.0-beta.10)
        # This method converts between the two formats.
        #
        # The regex matches:
        # - Stable: 16.2.0
        # - Beta (Ruby): 16.2.0.beta.10 or (npm): 16.2.0-beta.10
        # - RC (Ruby): 16.1.0.rc.1 or (npm): 16.1.0-rc.1
        # - Alpha (Ruby): 16.0.0.alpha.5 or (npm): 16.0.0-alpha.5
        # This ensures beta/rc versions use the exact version instead of "latest" which would
        # install the latest stable release and cause version mismatches.

        # Accept both dot and hyphen separators for pre-release versions
        version_with_optional_prerelease = /\A(\d+\.\d+\.\d+)([-.]([a-zA-Z0-9.]+))?\z/

        react_on_rails_pkg = if (match = ReactOnRails::VERSION.match(version_with_optional_prerelease))
                               base_version = match[1]
                               prerelease = match[3]

                               # Convert Ruby gem format (dot) to npm semver format (hyphen)
                               npm_version = if prerelease
                                               "#{base_version}-#{prerelease}"
                                             else
                                               base_version
                                             end

                               "react-on-rails@#{npm_version}"
                             else
                               puts "WARNING: Unrecognized version format #{ReactOnRails::VERSION}. " \
                                    "Adding the latest react-on-rails NPM module. " \
                                    "Double check this is correct in package.json"
                               "react-on-rails"
                             end

        puts "Installing React on Rails package..."
        return if add_package(react_on_rails_pkg)

        GeneratorMessages.add_warning(<<~MSG.strip)
          ⚠️  Failed to add react-on-rails package.

          You can install it manually by running:
            npm install #{react_on_rails_pkg}
        MSG
      rescue StandardError => e
        GeneratorMessages.add_warning(<<~MSG.strip)
          ⚠️  Error adding react-on-rails package: #{e.message}

          You can install it manually by running:
            npm install #{react_on_rails_pkg}
        MSG
      end

      def add_react_dependencies
        puts "Installing React dependencies..."
        return if add_packages(REACT_DEPENDENCIES)

        GeneratorMessages.add_warning(<<~MSG.strip)
          ⚠️  Failed to add React dependencies.

          You can install them manually by running:
            npm install #{REACT_DEPENDENCIES.join(' ')}
        MSG
      rescue StandardError => e
        GeneratorMessages.add_warning(<<~MSG.strip)
          ⚠️  Error adding React dependencies: #{e.message}

          You can install them manually by running:
            npm install #{REACT_DEPENDENCIES.join(' ')}
        MSG
      end

      def add_css_dependencies
        puts "Installing CSS handling dependencies..."
        return if add_packages(CSS_DEPENDENCIES)

        GeneratorMessages.add_warning(<<~MSG.strip)
          ⚠️  Failed to add CSS dependencies.

          You can install them manually by running:
            npm install #{CSS_DEPENDENCIES.join(' ')}
        MSG
      rescue StandardError => e
        GeneratorMessages.add_warning(<<~MSG.strip)
          ⚠️  Error adding CSS dependencies: #{e.message}

          You can install them manually by running:
            npm install #{CSS_DEPENDENCIES.join(' ')}
        MSG
      end

      def add_rspack_dependencies
        puts "Installing Rspack core dependencies..."
        return if add_packages(RSPACK_DEPENDENCIES)

        GeneratorMessages.add_warning(<<~MSG.strip)
          ⚠️  Failed to add Rspack dependencies.

          You can install them manually by running:
            npm install #{RSPACK_DEPENDENCIES.join(' ')}
        MSG
      rescue StandardError => e
        GeneratorMessages.add_warning(<<~MSG.strip)
          ⚠️  Error adding Rspack dependencies: #{e.message}

          You can install them manually by running:
            npm install #{RSPACK_DEPENDENCIES.join(' ')}
        MSG
      end

      def add_swc_dependencies
        puts "Installing SWC transpiler dependencies (20x faster than Babel)..."
        return if add_packages(SWC_DEPENDENCIES, dev: true)

        GeneratorMessages.add_warning(<<~MSG.strip)
          ⚠️  Failed to add SWC dependencies.

          SWC is the default JavaScript transpiler for Shakapacker 9.3.0+.
          You can install them manually by running:
            npm install --save-dev #{SWC_DEPENDENCIES.join(' ')}
        MSG
      rescue StandardError => e
        GeneratorMessages.add_warning(<<~MSG.strip)
          ⚠️  Error adding SWC dependencies: #{e.message}

          You can install them manually by running:
            npm install --save-dev #{SWC_DEPENDENCIES.join(' ')}
        MSG
      end

      def add_babel_react_dependencies
        puts "Installing Babel React preset dependency..."
        return if add_packages(BABEL_REACT_DEPENDENCIES, dev: true)

        GeneratorMessages.add_warning(<<~MSG.strip)
          ⚠️  Failed to add Babel React preset dependency.

          You can install it manually by running:
            npm install --save-dev #{BABEL_REACT_DEPENDENCIES.join(' ')}
        MSG
      rescue StandardError => e
        GeneratorMessages.add_warning(<<~MSG.strip)
          ⚠️  Error adding Babel React preset dependency: #{e.message}

          You can install it manually by running:
            npm install --save-dev #{BABEL_REACT_DEPENDENCIES.join(' ')}
        MSG
      end

      def add_typescript_dependencies
        puts "Installing TypeScript dependencies..."
        return if add_packages(TYPESCRIPT_DEPENDENCIES, dev: true)

        GeneratorMessages.add_warning(<<~MSG.strip)
          ⚠️  Failed to add TypeScript dependencies.

          You can install them manually by running:
            npm install --save-dev #{TYPESCRIPT_DEPENDENCIES.join(' ')}
        MSG
      rescue StandardError => e
        GeneratorMessages.add_warning(<<~MSG.strip)
          ⚠️  Error adding TypeScript dependencies: #{e.message}

          You can install them manually by running:
            npm install --save-dev #{TYPESCRIPT_DEPENDENCIES.join(' ')}
        MSG
      end

      def add_dev_dependencies
        puts "Installing development dependencies..."

        # Use Rspack-specific dev dependencies if --rspack flag is set
        dev_deps = if respond_to?(:options) && options&.rspack?
                     RSPACK_DEV_DEPENDENCIES
                   else
                     DEV_DEPENDENCIES
                   end

        return if add_packages(dev_deps, dev: true)

        GeneratorMessages.add_warning(<<~MSG.strip)
          ⚠️  Failed to add development dependencies.

          You can install them manually by running:
            npm install --save-dev #{dev_deps.join(' ')}
        MSG
      rescue StandardError => e
        GeneratorMessages.add_warning(<<~MSG.strip)
          ⚠️  Error adding development dependencies: #{e.message}

          You can install them manually by running:
            npm install --save-dev #{dev_deps.join(' ')}
        MSG
      end

      # Add a single dependency using package_json gem
      #
      # This method is used internally for adding the react-on-rails package
      # with version-specific handling (react-on-rails@VERSION).
      # For batch operations, use add_packages instead.
      #
      # The exact: true flag ensures version pinning aligns with the gem version,
      # preventing version mismatches between the Ruby gem and NPM package.
      #
      # @param package [String] Package specifier (e.g., "react-on-rails@16.0.0")
      # @param dev [Boolean] Whether to add as dev dependency
      # @return [Boolean] true if successful, false otherwise
      def add_package(package, dev: false)
        pj = package_json
        return false unless pj

        begin
          # Ensure package is in array format for package_json gem
          packages_array = [package]
          if dev
            pj.manager.add(packages_array, type: :dev, exact: true)
          else
            pj.manager.add(packages_array, exact: true)
          end
          true
        rescue StandardError
          # Return false to trigger warning in calling method
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
      def add_packages(packages, dev: false)
        # Use the add_npm_dependencies helper from GeneratorHelper
        add_npm_dependencies(packages, dev: dev)
      end

      def install_js_dependencies
        # Use package_json gem's install method (always available via shakapacker)
        # package_json is guaranteed to be available because:
        # 1. react_on_rails gemspec requires shakapacker
        # 2. shakapacker gemspec requires package_json
        # 3. GeneratorHelper provides package_json method
        pj = package_json
        unless pj
          GeneratorMessages.add_warning("package_json not available, skipping dependency installation")
          return false
        end

        pj.manager.install
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
  end
end
# rubocop:enable Metrics/ModuleLength

# frozen_string_literal: true

require_relative "generator_messages"

# rubocop:disable Metrics/ModuleLength
module ReactOnRails
  module Generators
    # Shared module for managing JavaScript dependencies across generators
    # This module provides common functionality for adding and installing
    # JS dependencies to avoid code duplication between generators.
    #
    # For older shakapacker versions, the package_json gem may not be available.
    # In that case this module falls back to direct package-manager commands.
    #
    # == Required Methods
    # Including classes must include GeneratorHelper module which provides:
    # - add_npm_dependencies(packages, dev: false): Add packages via package_json gem
    # - package_json: Access to PackageJson instance (always available via shakapacker)
    # - destination_root: Generator destination directory
    # - using_rspack?: Returns true if rspack is the configured bundler
    #   (called unconditionally; provided by GeneratorHelper)
    # - using_swc?: Returns true if SWC is the configured transpiler
    #   (called unconditionally; provided by GeneratorHelper)
    #
    # == Optional Methods
    # Including classes may define:
    # - use_pro?: Returns true if React on Rails Pro should be used
    # - use_rsc?: Returns true if React Server Components should be used
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
      # Third-party dependencies are pinned to ^major.0.0 ranges to prevent breaking
      # changes from uncontrolled major version bumps (e.g., peer dependency conflicts)
      # while still allowing minor/patch updates. Pre-1.0 packages are left bare since
      # ^0.x ranges pin to the minor version, which is too narrow.
      # SWC pins match Shakapacker's own version constraints.
      #
      # Update these pins deliberately when adopting a new major version.

      # Core React dependencies required for React on Rails
      # Note: @babel/preset-react is handled separately in BABEL_REACT_DEPENDENCIES
      # and is added only when SWC is not the active transpiler.
      REACT_DEPENDENCIES = %w[
        react@^19.0.0
        react-dom@^19.0.0
        prop-types@^15.0.0
      ].freeze

      # Babel preset needed by the generated babel.config.js for non-SWC setups.
      BABEL_REACT_DEPENDENCIES = %w[
        @babel/preset-react@^7.0.0
      ].freeze

      # CSS processing dependencies for webpack
      CSS_DEPENDENCIES = %w[
        css-loader@^7.0.0
        css-minimizer-webpack-plugin@^8.0.0
        mini-css-extract-plugin@^2.0.0
        style-loader@^4.0.0
      ].freeze

      # Development-only dependencies for hot reloading (Webpack)
      # Both packages are pre-1.0, so left bare (see pinning note above).
      DEV_DEPENDENCIES = %w[
        @pmmmwh/react-refresh-webpack-plugin
        react-refresh
      ].freeze

      # Rspack core dependencies (only installed when --rspack flag is used)
      RSPACK_DEPENDENCIES = %w[
        @rspack/core@^1.0.0
        rspack-manifest-plugin@^5.0.0
      ].freeze

      # Rspack development dependencies for hot reloading
      # react-refresh is pre-1.0, so left bare (see pinning note above).
      RSPACK_DEV_DEPENDENCIES = %w[
        @rspack/cli@^1.0.0
        @rspack/plugin-react-refresh@^1.0.0
        react-refresh
      ].freeze

      # TypeScript dependencies (only installed when --typescript flag is used)
      # Note: @babel/preset-typescript is NOT included because:
      # - SWC is now the default javascript_transpiler (has built-in TypeScript support)
      # - Shakapacker handles the transpiler configuration via shakapacker.yml
      # - If users choose javascript_transpiler: 'babel', they should manually add @babel/preset-typescript
      #   and configure it in their babel.config.js
      TYPESCRIPT_DEPENDENCIES = %w[
        typescript@^6.0.0
        @types/react@^19.0.0
        @types/react-dom@^19.0.0
      ].freeze

      # SWC transpiler dependencies (for Shakapacker 9.3.0+ default transpiler)
      # SWC is ~20x faster than Babel and is the default for new Shakapacker installations
      # Version ranges match Shakapacker's own constraints.
      SWC_DEPENDENCIES = %w[
        @swc/core@^1.3.0
        swc-loader@^0.2.0
      ].freeze

      # React on Rails Pro dependencies (only installed when --pro or --rsc flag is used)
      # These packages are published publicly on npmjs.org but require a license for production use
      PRO_DEPENDENCIES = %w[
        react-on-rails-pro
        react-on-rails-pro-node-renderer
      ].freeze

      # React Server Components dependencies (only installed when --rsc flag is used)
      # Requires React 19.0.x - see https://react.dev/reference/rsc/server-components
      RSC_DEPENDENCIES = %w[
        react-on-rails-rsc
      ].freeze

      # RSC package releases follow the React 19.0.x line (independent from gem versioning).
      RSC_REACT_VERSION_RANGE = "~19.0.4"
      RSC_PACKAGE_VERSION_PIN = "19.0.4"

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
        using_pro = respond_to?(:use_pro?) && use_pro?
        using_rsc = respond_to?(:use_rsc?) && use_rsc?
        # Pro package includes react-on-rails, so skip base package when using Pro
        add_react_on_rails_package unless using_pro
        add_react_dependencies
        add_css_dependencies
        add_rspack_dependencies if using_rspack?
        add_transpiler_dependencies
        add_pro_dependencies if using_pro
        add_rsc_dependencies if using_rsc
        add_dev_dependencies
      end

      def add_transpiler_dependencies
        add_swc_dependencies if using_swc?
        add_babel_react_dependencies if !using_swc? && !using_rspack?
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
                               say_status :warning,
                                          "Unrecognized version format #{ReactOnRails::VERSION}. " \
                                          "Adding the latest react-on-rails NPM module. " \
                                          "Double check this is correct in package.json",
                                          :yellow
                               "react-on-rails"
                             end

        say "Installing React on Rails package..."
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
        say "Installing React dependencies..."

        # RSC requires React 19.0.x specifically (not 19.1.x or later)
        # Pin to ~19.0.4 to allow patch updates while staying within 19.0.x
        react_deps = if respond_to?(:use_rsc?) && use_rsc?
                       ["react@#{RSC_REACT_VERSION_RANGE}", "react-dom@#{RSC_REACT_VERSION_RANGE}", "prop-types"]
                     else
                       REACT_DEPENDENCIES
                     end

        return if add_packages(react_deps)

        GeneratorMessages.add_warning(<<~MSG.strip)
          ⚠️  Failed to add React dependencies.

          You can install them manually by running:
            npm install #{react_deps.join(' ')}
        MSG
      rescue StandardError => e
        GeneratorMessages.add_warning(<<~MSG.strip)
          ⚠️  Error adding React dependencies: #{e.message}

          You can install them manually by running:
            npm install #{react_deps.join(' ')}
        MSG
      end

      def add_css_dependencies
        say "Installing CSS handling dependencies..."
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
        say "Installing Rspack core dependencies..."
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
        say "Installing SWC transpiler dependencies (20x faster than Babel)..."
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
        say "Installing Babel React preset dependency..."
        return true if add_packages(BABEL_REACT_DEPENDENCIES, dev: true)

        GeneratorMessages.add_warning(<<~MSG.strip)
          ⚠️  Failed to add Babel React preset dependency.

          You can install it manually by running:
            npm install --save-dev #{BABEL_REACT_DEPENDENCIES.join(' ')}
        MSG
        false
      rescue StandardError => e
        GeneratorMessages.add_warning(<<~MSG.strip)
          ⚠️  Error adding Babel React preset dependency: #{e.message}

          You can install it manually by running:
            npm install --save-dev #{BABEL_REACT_DEPENDENCIES.join(' ')}
        MSG
        false
      end

      def add_typescript_dependencies
        say "Installing TypeScript dependencies..."
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

      def add_pro_dependencies
        say "Installing React on Rails Pro dependencies..."

        # When upgrading from base React on Rails to Pro, remove the base package first
        # Pro package includes all base functionality, so having both causes validation errors
        remove_base_package_if_present

        # Pin to exact version matching the gem (converts Ruby format to npm format)
        # Falls back to latest if version can't be determined
        pro_packages = pro_packages_with_version
        results = pro_packages.map { |pkg| add_package(pkg) }
        return if results.all?

        GeneratorMessages.add_warning(<<~MSG.strip)
          ⚠️  Failed to add React on Rails Pro dependencies.

          You can install them manually by running:
            npm install #{pro_packages.join(' ')}
        MSG
      rescue StandardError => e
        GeneratorMessages.add_warning(<<~MSG.strip)
          ⚠️  Error adding React on Rails Pro dependencies: #{e.message}

          You can install them manually by running:
            npm install #{PRO_DEPENDENCIES.join(' ')}
        MSG
      end

      # Returns Pro package names with version suffix matching the gem version.
      # Uses VersionSyntaxConverter to handle Ruby->npm format conversion.
      # Falls back to ReactOnRails::VERSION since Pro and base gems share the same version.
      def pro_packages_with_version
        # Prefer Pro gem version if loaded; fall back to base gem version (same by policy).
        # After auto-install via bundle add, the Pro gem isn't loaded in the current process,
        # so ReactOnRailsPro::VERSION won't be defined. The base gem version is always available.
        gem_version = defined?(ReactOnRailsPro::VERSION) ? ReactOnRailsPro::VERSION : ReactOnRails::VERSION
        npm_version = ReactOnRails::VersionSyntaxConverter.new.rubygem_to_npm(gem_version)
        PRO_DEPENDENCIES.map { |pkg| "#{pkg}@#{npm_version}" }
      rescue StandardError
        say_status :warning, "Could not determine Pro package version. Installing latest.", :yellow
        PRO_DEPENDENCIES
      end

      def add_rsc_dependencies
        say "Installing React Server Components dependencies..."
        rsc_packages, used_version_pins = rsc_packages_with_version
        return if add_packages(rsc_packages)

        manual_install_packages = rsc_packages
        if used_version_pins
          warning_msg = "Could not install version-pinned RSC dependency. Retrying latest available package."
          say_status :warning,
                     warning_msg,
                     :yellow
          GeneratorMessages.add_warning(
            "Warning: #{warning_msg} " \
            "The installed react-on-rails-rsc version may not match the expected compatibility pin."
          )
          return if add_packages(RSC_DEPENDENCIES)

          manual_install_packages = RSC_DEPENDENCIES
        end

        GeneratorMessages.add_warning(<<~MSG.strip)
          ⚠️  Failed to add React Server Components dependencies.

          You can install them manually by running:
            npm install #{manual_install_packages.join(' ')}
        MSG
      rescue StandardError => e
        GeneratorMessages.add_warning(<<~MSG.strip)
          ⚠️  Error adding React Server Components dependencies: #{e.message}

          You can install them manually by running:
            npm install #{RSC_DEPENDENCIES.join(' ')}
        MSG
      end

      # Returns [pinned_packages, used_version_pins]. used_version_pins is always true here;
      # subclasses may override to return [packages, false] when pinning should be skipped.
      def rsc_packages_with_version
        [RSC_DEPENDENCIES.map { |pkg| "#{pkg}@#{RSC_PACKAGE_VERSION_PIN}" }, true]
      end

      def remove_base_package_if_present
        pj = package_json
        return unless pj

        dependencies = pj.fetch("dependencies", {})
        return unless dependencies.key?("react-on-rails")

        say "Removing base 'react-on-rails' package (Pro package includes all base functionality)..."
        pj.manager.remove(["react-on-rails"])
        say "✅ Removed 'react-on-rails' package"
      rescue StandardError => e
        GeneratorMessages.add_warning(<<~MSG.strip)
          ⚠️  Could not remove base 'react-on-rails' package: #{e.message}

          Please remove it manually:
            npm uninstall react-on-rails
        MSG
      end

      def add_dev_dependencies
        say "Installing development dependencies..."

        # Use Rspack-specific dev dependencies if rspack is configured
        dev_deps = using_rspack? ? RSPACK_DEV_DEPENDENCIES : DEV_DEPENDENCIES

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

      # Add a single dependency.
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
        add_packages([package], dev: dev)
      end

      # Add multiple dependencies.
      #
      # Tries package_json first (when available), then falls back to invoking
      # the detected package manager directly.
      #
      # @param packages [Array<String>] Package names to add
      # @param dev [Boolean] Whether to add as dev dependencies
      # @return [Boolean] true if successful, false otherwise
      def add_packages(packages, dev: false)
        return true if add_npm_dependencies(packages, dev: dev)

        install_packages_with_fallback(packages, dev: dev)
      end

      def install_js_dependencies
        pj = package_json
        if pj
          pj.manager.install
          return true
        end

        package_manager = fallback_package_manager
        install_args = [package_manager, "install"]

        return true if system(*install_args)

        GeneratorMessages.add_warning(<<~MSG.strip)
          ⚠️  JavaScript dependencies installation failed via #{package_manager}.

          Please run manually:
            #{install_args.join(' ')}
        MSG
        false
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

      def install_packages_with_fallback(packages, dev:)
        package_manager = fallback_package_manager
        packages_to_install = filter_missing_packages(packages)
        return true if packages_to_install.empty?

        install_args = build_install_args(package_manager, dev, packages_to_install)

        system(*install_args)
      rescue StandardError => e
        GeneratorMessages.add_warning("⚠️  Fallback package install failed: #{e.message}")
        false
      end

      def fallback_package_manager
        package_manager = GeneratorMessages.detect_package_manager
        return package_manager if GeneratorMessages.supported_package_manager?(package_manager)

        "npm"
      end

      def build_install_args(package_manager, dev, packages)
        base_commands = {
          "npm" => %w[npm install --save-exact],
          "yarn" => %w[yarn add --exact],
          "pnpm" => %w[pnpm add --save-exact],
          "bun" => %w[bun add --exact]
        }

        base_args = base_commands.fetch(package_manager).dup
        base_args << dev_flag_for(package_manager) if dev
        base_args + packages
      end

      def dev_flag_for(package_manager)
        case package_manager
        when "npm", "pnpm" then "--save-dev"
        when "yarn", "bun" then "--dev"
        else
          raise ArgumentError, "Unknown package manager for dev flag: #{package_manager}"
        end
      end

      def filter_missing_packages(packages)
        existing = existing_package_names
        return packages if existing.empty?

        packages.reject do |package_spec|
          package_name = package_name_from_spec(package_spec)
          next false unless package_name && existing.include?(package_name)

          !version_specified?(package_spec, package_name)
        end
      end

      def existing_package_names
        return [] unless File.exist?("package.json")

        content = JSON.parse(File.read("package.json"))
        dependencies = content.fetch("dependencies", {}).keys
        dev_dependencies = content.fetch("devDependencies", {}).keys
        (dependencies + dev_dependencies).uniq
      rescue StandardError
        []
      end

      def package_name_from_spec(package_spec)
        scoped_match = package_spec.match(%r{\A(@[^/]+/[^@]+)(?:@.+)?\z})
        return scoped_match[1] if scoped_match

        unscoped_match = package_spec.match(/\A([^@]+)(?:@.+)?\z/)
        unscoped_match&.[](1)
      end

      def version_specified?(package_spec, package_name)
        package_spec != package_name
      end
    end
  end
end
# rubocop:enable Metrics/ModuleLength

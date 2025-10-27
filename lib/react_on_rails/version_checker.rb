# frozen_string_literal: true

module ReactOnRails
  # Responsible for checking versions of rubygem versus yarn node package
  # against each other at runtime.
  class VersionChecker
    attr_reader :node_package_version

    # Semver uses - to separate pre-release, but RubyGems use .
    VERSION_PARTS_REGEX = /(\d+)\.(\d+)\.(\d+)(?:[-.]([0-9A-Za-z.-]+))?/

    def self.build
      new(NodePackageVersion.build)
    end

    def initialize(node_package_version)
      @node_package_version = node_package_version
    end

    # Validates version and package compatibility.
    # Raises ReactOnRails::Error if:
    # - package.json file is not found
    # - Both react-on-rails and react-on-rails-pro packages are installed
    # - Pro gem is installed but using react-on-rails package
    # - Pro package is installed but Pro gem is not installed
    # - Non-exact version is used
    # - Versions don't match
    def validate_version_and_package_compatibility!
      validate_package_json_exists!
      validate_package_gem_compatibility!
      validate_exact_version!
      validate_version_match!
    end

    private

    def validate_package_json_exists!
      return if File.exist?(node_package_version.package_json)

      base_install_cmd = ReactOnRails::Utils.package_manager_install_exact_command("react-on-rails", gem_version)
      pro_install_cmd = ReactOnRails::Utils.package_manager_install_exact_command("react-on-rails-pro", gem_version)

      raise ReactOnRails::Error, <<~MSG.strip
        **ERROR** ReactOnRails: package.json file not found.

        Expected location: #{node_package_version.package_json}

        React on Rails requires a package.json file with either 'react-on-rails' or
        'react-on-rails-pro' package installed.

        Fix:
          1. Ensure you have a package.json in your project root
          2. Run: #{base_install_cmd}

          Or if using React on Rails Pro:
          Run: #{pro_install_cmd}
      MSG
    end

    def validate_package_gem_compatibility!
      has_base_package = node_package_version.react_on_rails_package?
      has_pro_package = node_package_version.react_on_rails_pro_package?
      is_pro_gem = ReactOnRails::Utils.react_on_rails_pro?

      validate_packages_installed!(has_base_package, has_pro_package)
      validate_no_duplicate_packages!(has_base_package, has_pro_package)
      validate_pro_gem_uses_pro_package!(is_pro_gem, has_pro_package)
      validate_pro_package_has_pro_gem!(is_pro_gem, has_pro_package)
    end

    def validate_packages_installed!(has_base_package, has_pro_package)
      return if has_base_package || has_pro_package

      base_install_cmd = ReactOnRails::Utils.package_manager_install_exact_command("react-on-rails", gem_version)
      pro_install_cmd = ReactOnRails::Utils.package_manager_install_exact_command("react-on-rails-pro", gem_version)

      raise ReactOnRails::Error, <<~MSG.strip
        **ERROR** ReactOnRails: No React on Rails npm package is installed.

        You must install either 'react-on-rails' or 'react-on-rails-pro' package.

        Fix:
          If using the standard (free) version:
          Run: #{base_install_cmd}

          Or if using React on Rails Pro:
          Run: #{pro_install_cmd}

        #{package_json_location}
      MSG
    end

    def validate_no_duplicate_packages!(has_base_package, has_pro_package)
      return unless has_base_package && has_pro_package

      remove_cmd = ReactOnRails::Utils.package_manager_remove_command("react-on-rails")

      raise ReactOnRails::Error, <<~MSG.strip
        **ERROR** ReactOnRails: Both 'react-on-rails' and 'react-on-rails-pro' packages are installed.

        If you're using React on Rails Pro, only install the 'react-on-rails-pro' package.
        The Pro package already includes all functionality from the base package.

        Fix:
          1. Remove 'react-on-rails' from your package.json dependencies
          2. Run: #{remove_cmd}
          3. Keep only: react-on-rails-pro

        #{package_json_location}
      MSG
    end

    def validate_pro_gem_uses_pro_package!(is_pro_gem, has_pro_package)
      return unless is_pro_gem && !has_pro_package

      remove_cmd = ReactOnRails::Utils.package_manager_remove_command("react-on-rails")
      install_cmd = ReactOnRails::Utils.package_manager_install_exact_command("react-on-rails-pro", gem_version)

      raise ReactOnRails::Error, <<~MSG.strip
        **ERROR** ReactOnRails: You have the Pro gem installed but are using the base 'react-on-rails' package.

        When using React on Rails Pro, you must use the 'react-on-rails-pro' npm package.

        Fix:
          1. Remove the base package: #{remove_cmd}
          2. Install the Pro package: #{install_cmd}

        #{package_json_location}
      MSG
    end

    def validate_pro_package_has_pro_gem!(is_pro_gem, has_pro_package)
      return unless !is_pro_gem && has_pro_package

      remove_pro_cmd = ReactOnRails::Utils.package_manager_remove_command("react-on-rails-pro")
      install_base_cmd = ReactOnRails::Utils.package_manager_install_exact_command("react-on-rails", gem_version)

      raise ReactOnRails::Error, <<~MSG.strip
        **ERROR** ReactOnRails: You have the 'react-on-rails-pro' package installed but the Pro gem is not installed.

        The Pro npm package requires the Pro gem to function.

        Fix:
          1. Install the Pro gem by adding to your Gemfile:
             gem 'react_on_rails_pro'
          2. Run: bundle install

        Or if you meant to use the base version:
          1. Remove the Pro package: #{remove_pro_cmd}
          2. Install the base package: #{install_base_cmd}

        #{package_json_location}
      MSG
    end

    def validate_exact_version!
      return if node_package_version.raw.nil? || node_package_version.local_path_or_url?

      return unless node_package_version.semver_wildcard?

      package_name = node_package_version.package_name
      install_cmd = ReactOnRails::Utils.package_manager_install_exact_command(package_name, gem_version)

      raise ReactOnRails::Error, <<~MSG.strip
        **ERROR** ReactOnRails: The '#{package_name}' package version is not an exact version.

        Detected: #{node_package_version.raw}
             Gem: #{gem_version}

        React on Rails requires exact version matching between the gem and npm package.
        Do not use ^, ~, >, <, *, or other semver ranges.

        Fix:
          Run: #{install_cmd}

        #{package_json_location}
      MSG
    end

    def validate_version_match!
      return if node_package_version.raw.nil? || node_package_version.local_path_or_url?

      return if node_package_version.parts == gem_version_parts

      package_name = node_package_version.package_name
      install_cmd = ReactOnRails::Utils.package_manager_install_exact_command(package_name, gem_version)

      raise ReactOnRails::Error, <<~MSG.strip
        **ERROR** ReactOnRails: The '#{package_name}' package version does not match the gem version.

        Package: #{node_package_version.raw}
            Gem: #{gem_version}

        The npm package and gem versions must match exactly for compatibility.

        Fix:
          Run: #{install_cmd}

        #{package_json_location}
      MSG
    end

    def gem_version
      ReactOnRails::VERSION
    end

    def gem_version_parts
      gem_version.match(VERSION_PARTS_REGEX)&.captures&.compact
    end

    def package_json_location
      "Package.json location: #{VersionChecker::NodePackageVersion.package_json_path}"
    end

    class NodePackageVersion
      attr_reader :package_json

      def self.build
        new(package_json_path)
      end

      def self.package_json_path
        Rails.root.join(ReactOnRails.configuration.node_modules_location, "package.json")
      end

      def initialize(package_json)
        @package_json = package_json
      end

      def raw
        return @raw if defined?(@raw)

        return @raw = nil unless File.exist?(package_json)

        parsed = parsed_package_contents
        return @raw = nil unless parsed.key?("dependencies")

        deps = parsed["dependencies"]

        # Check for react-on-rails-pro first (Pro takes precedence)
        return @raw = deps["react-on-rails-pro"] if deps.key?("react-on-rails-pro")

        # Fall back to react-on-rails
        return @raw = deps["react-on-rails"] if deps.key?("react-on-rails")

        # Neither package found
        msg = "No 'react-on-rails' or 'react-on-rails-pro' entry in the dependencies of " \
              "#{NodePackageVersion.package_json_path}, which is the expected location according to " \
              "ReactOnRails.configuration.node_modules_location"
        Rails.logger.warn(msg)
        @raw = nil
      end

      def react_on_rails_package?
        package_installed?("react-on-rails")
      end

      def react_on_rails_pro_package?
        package_installed?("react-on-rails-pro")
      end

      def package_name
        return "react-on-rails-pro" if react_on_rails_pro_package?

        "react-on-rails"
      end

      def semver_wildcard?
        # See https://docs.npmjs.com/cli/v10/configuring-npm/package-json#dependencies
        # We want to disallow all expressions other than exact versions
        # and the ones allowed by local_path_or_url?
        return true if raw.blank?

        special_version_string? || wildcard_or_x_range? || range_operator? || range_syntax?
      end

      def special_version_string?
        %w[latest next canary beta alpha rc].include?(raw.downcase)
      end

      def wildcard_or_x_range?
        raw == "*" ||
          raw =~ /^[xX*]$/ ||
          raw =~ /^[xX*]\./ ||
          raw =~ /\.[xX*]\b/ ||
          raw =~ /\.[xX*]$/
      end

      def range_operator?
        raw.start_with?(/[~^><*]/)
      end

      def range_syntax?
        raw.include?(" - ") || raw.include?(" || ")
      end

      def local_path_or_url?
        # See https://docs.npmjs.com/cli/v10/configuring-npm/package-json#dependencies
        # All path and protocol "version ranges" include / somewhere,
        # but we want to make an exception for npm:@scope/pkg@version.
        !raw.nil? && raw.include?("/") && !raw.start_with?("npm:")
      end

      def parts
        return if local_path_or_url?

        match = raw.match(VERSION_PARTS_REGEX)
        unless match
          raise ReactOnRails::Error, "Cannot parse version number '#{raw}' (only exact versions are supported)"
        end

        match.captures.compact
      end

      private

      def package_installed?(package_name)
        return false unless File.exist?(package_json)

        parsed = parsed_package_contents
        parsed.dig("dependencies", package_name).present?
      end

      def package_json_contents
        @package_json_contents ||= File.read(package_json)
      end

      def parsed_package_contents
        return @parsed_package_contents if defined?(@parsed_package_contents)

        begin
          @parsed_package_contents = JSON.parse(package_json_contents)
        rescue JSON::ParserError => e
          raise ReactOnRails::Error, <<~MSG.strip
            **ERROR** ReactOnRails: Failed to parse package.json file.

            Location: #{package_json}
            Error: #{e.message}

            The package.json file contains invalid JSON. Please check the file for syntax errors.

            Common issues:
              - Missing or extra commas
              - Unquoted keys or values
              - Trailing commas (not allowed in JSON)
              - Comments (not allowed in standard JSON)
          MSG
        end
      end
    end
  end
end

# frozen_string_literal: true

module ReactOnRails
  # Responsible for checking versions of rubygem versus yarn node package
  # against each other at runtime.
  class VersionChecker
    attr_reader :package_json_data

    # Semver uses - to separate pre-release, but RubyGems use .
    VERSION_PARTS_REGEX = /(\d+)\.(\d+)\.(\d+)(?:[-.]([0-9A-Za-z.-]+))?/

    def self.build
      new(PackageJsonData.build)
    end

    def initialize(package_json_data)
      @package_json_data = package_json_data
    end

    # For compatibility, the gem and the node package versions should always match,
    # unless the user really knows what they're doing. So we will give a
    # warning if they do not.
    def log_if_gem_and_node_package_versions_differ
      errors = []

      # Check if both react-on-rails and react-on-rails-pro are present
      check_for_both_packages(errors)

      # Check react-on-rails or react-on-rails-pro package
      check_main_package_version(errors)

      # Check node-renderer package if Pro is present
      check_node_renderer_version(errors) if package_json_data.pro_package?

      # Handle errors based on environment
      handle_errors(errors) if errors.any?
    end

    private

    def check_for_both_packages(errors)
      return unless package_json_data.both_packages?

      msg = <<~MSG.strip_heredoc
        React on Rails: Both 'react-on-rails' and 'react-on-rails-pro' packages are detected in package.json.
        You only need to install 'react-on-rails-pro' package as it already includes 'react-on-rails' as a dependency.
        Please remove 'react-on-rails' from your package.json dependencies.
      MSG
      errors << { type: :warning, message: msg }
    end

    def check_main_package_version(errors)
      package_name = package_json_data.pro_package? ? "react-on-rails-pro" : "react-on-rails"
      package_version_data = package_json_data.get_package_version(package_name)

      return if package_version_data.nil?
      return if package_version_data.local_path_or_url?

      # Check for exact version (no semver wildcards)
      if package_version_data.semver_wildcard?
        msg = build_semver_wildcard_error(package_name, package_version_data.raw)
        errors << { type: :error, message: msg }
        return
      end

      # Check version match
      expected_version = package_json_data.pro_package? ? pro_gem_version : gem_version
      return if package_version_data.parts == version_parts(expected_version)

      msg = build_version_mismatch_error(package_name, package_version_data.raw, expected_version)
      errors << { type: :error, message: msg }
    end

    def check_node_renderer_version(errors)
      node_renderer_data = package_json_data.get_package_version("@shakacode-tools/react-on-rails-pro-node-renderer")
      return if node_renderer_data.nil?
      return if node_renderer_data.local_path_or_url?

      # Check for exact version
      if node_renderer_data.semver_wildcard?
        msg = build_semver_wildcard_error("@shakacode-tools/react-on-rails-pro-node-renderer",
                                          node_renderer_data.raw)
        errors << { type: :error, message: msg }
        return
      end

      # Check version match with Pro gem
      return if node_renderer_data.parts == version_parts(pro_gem_version)

      msg = build_version_mismatch_error("@shakacode-tools/react-on-rails-pro-node-renderer",
                                         node_renderer_data.raw, pro_gem_version)
      errors << { type: :error, message: msg }
    end

    def build_semver_wildcard_error(package_name, raw_version)
      <<~MSG.strip_heredoc
        React on Rails: Package '#{package_name}' is using a non-exact version: #{raw_version}
        For guaranteed compatibility, you must use exact versions (no ^, ~, >=, etc.).
        Run: yarn add #{package_name}@#{expected_version_for_package(package_name)} --exact
      MSG
    end

    def build_version_mismatch_error(package_name, package_version, gem_version)
      <<~MSG.strip_heredoc
        React on Rails: Package '#{package_name}' version does not match the gem version.
        Package version: #{package_version}
        Gem version:     #{gem_version}
        Run: yarn add #{package_name}@#{gem_version} --exact
      MSG
    end

    def expected_version_for_package(package_name)
      case package_name
      when "react-on-rails"
        gem_version
      when "react-on-rails-pro", "@shakacode-tools/react-on-rails-pro-node-renderer"
        pro_gem_version
      end
    end

    def handle_errors(errors)
      errors.each do |error|
        if error[:type] == :warning
          Rails.logger.warn("**WARNING** #{error[:message]}")
        elsif development_or_test?
          raise ReactOnRails::Error, error[:message]
        else
          Rails.logger.error("**ERROR** #{error[:message]}")
        end
      end
    end

    def development_or_test?
      Rails.env.development? || Rails.env.test?
    end

    def gem_version
      ReactOnRails::VERSION
    end

    def pro_gem_version
      return nil unless defined?(ReactOnRailsPro)

      ReactOnRailsPro::VERSION
    end

    def version_parts(version)
      version&.match(VERSION_PARTS_REGEX)&.captures&.compact
    end

    # Represents package.json data and provides methods to check for packages
    class PackageJsonData
      attr_reader :package_json_path

      def self.build
        new(package_json_path)
      end

      def self.package_json_path
        Rails.root.join(ReactOnRails.configuration.node_modules_location, "package.json")
      end

      def initialize(package_json_path)
        @package_json_path = package_json_path
      end

      def pro_package?
        package_exists?("react-on-rails-pro")
      end

      def main_package?
        package_exists?("react-on-rails")
      end

      def both_packages?
        main_package? && pro_package?
      end

      def get_package_version(package_name)
        version = find_package_version(package_name)
        return nil if version.nil?

        PackageVersion.new(version)
      end

      private

      def package_exists?(package_name)
        !find_package_version(package_name).nil?
      end

      def find_package_version(package_name)
        return nil unless File.exist?(package_json_path)

        parsed = parsed_package_json
        return nil unless parsed

        parsed.dig("dependencies", package_name) || parsed.dig("devDependencies", package_name)
      end

      def parsed_package_json
        return @parsed_package_json if defined?(@parsed_package_json)

        @parsed_package_json = begin
          JSON.parse(File.read(package_json_path))
        rescue JSON::ParserError, Errno::ENOENT
          nil
        end
      end
    end

    # Represents a package version string from package.json
    class PackageVersion
      attr_reader :raw

      def initialize(raw)
        @raw = raw
      end

      def semver_wildcard?
        # See https://docs.npmjs.com/cli/v10/configuring-npm/package-json#dependencies
        # We want to disallow all expressions other than exact versions
        # and the ones allowed by local_path_or_url?
        raw.blank? || raw.start_with?(/[~^><*]/) || raw.include?(" - ") || raw.include?(" || ")
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
    end
  end
end

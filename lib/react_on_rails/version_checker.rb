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

    # For compatibility, the gem and the node package versions should always match,
    # unless the user really knows what they're doing. So we will give a
    # warning if they do not.
    def log_if_gem_and_node_package_versions_differ
      return if node_package_version.raw.nil? || node_package_version.local_path_or_url?
      return log_node_semver_version_warning if node_package_version.semver_wildcard?

      log_differing_versions_warning unless node_package_version.parts == gem_version_parts
    end

    private

    def common_error_msg
      <<-MSG.strip_heredoc
         Detected: #{node_package_version.raw}
              gem: #{gem_version}
         Ensure the installed version of the gem is the same as the version of
         your installed Node package. Do not use >= or ~> in your Gemfile for react_on_rails.
         Do not use ^, ~, or other non-exact versions in your package.json for react-on-rails.
         Run `yarn add react-on-rails --exact` in the directory containing folder node_modules.
      MSG
    end

    def log_differing_versions_warning
      msg = "**WARNING** ReactOnRails: ReactOnRails gem and Node package versions do not match\n#{common_error_msg}"
      Rails.logger.warn(msg)
    end

    def log_node_semver_version_warning
      msg = "**WARNING** ReactOnRails: Your Node package version for react-on-rails is not an exact version\n" \
            "#{common_error_msg}"
      Rails.logger.warn(msg)
    end

    def gem_version
      ReactOnRails::VERSION
    end

    def gem_version_parts
      gem_version.match(VERSION_PARTS_REGEX)&.captures.compact
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

        if File.exist?(package_json)
          parsed_package_contents = JSON.parse(package_json_contents)
          if parsed_package_contents.key?("dependencies") &&
             parsed_package_contents["dependencies"].key?("react-on-rails")
            return @raw = parsed_package_contents["dependencies"]["react-on-rails"]
          end
        end
        msg = "No 'react-on-rails' entry in the dependencies of #{NodePackageVersion.package_json_path}, " \
              "which is the expected location according to ReactOnRails.configuration.node_modules_location"
        Rails.logger.warn(msg)
        @raw = nil
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

      private

      def package_json_contents
        @package_json_contents ||= File.read(package_json)
      end
    end
  end
end

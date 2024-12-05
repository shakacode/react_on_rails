# frozen_string_literal: true

module ReactOnRails
  # Responsible for checking versions of rubygem versus yarn node package
  # against each other at runtime.
  class VersionChecker
    attr_reader :node_package_version

    MAJOR_MINOR_PATCH_VERSION_REGEX = /(\d+)\.(\d+)\.(\d+)/

    def self.build
      new(NodePackageVersion.build)
    end

    def self.instance(package_json_path)
      new(NodePackageVersion.new(package_json_path))
    end

    def initialize(node_package_version)
      @node_package_version = node_package_version
    end

    # For compatibility, the gem and the node package versions should always match,
    # unless the user really knows what they're doing. So we will give a
    # warning if they do not.
    def raise_if_gem_and_node_package_versions_differ
      return true unless node_package_version.raw
      return if node_package_version.relative_path?

      raise_node_semver_version_warning if node_package_version.semver_wildcard?

      versions_match = compare_versions(node_package_version.major_minor_patch, gem_major_minor_patch_version)

      raise_differing_versions_warning unless versions_match
      false
    end

    def log_if_gem_and_node_package_versions_differ
      return true unless node_package_version.raw
      return if node_package_version.relative_path?

      log_node_semver_version_warning if node_package_version.semver_wildcard?

      versions_match = compare_versions(node_package_version.major_minor_patch, gem_major_minor_patch_version)

      log_differing_versions_warning unless versions_match
      false
    end

    private

    def compare_versions(node_major_minor_patch, gem_major_minor_patch)
      node_major_minor_patch[0] == gem_major_minor_patch[0] &&
        node_major_minor_patch[1] == gem_major_minor_patch[1] &&
        node_major_minor_patch[2] == gem_major_minor_patch[2]
    end

    def common_error_msg
      <<-MSG.strip_heredoc
         Detected: #{node_package_version.raw}
              gem: #{gem_version}
         Ensure the installed version of the gem is the same as the version of
         your installed node package. Do not use >= or ~> in your Gemfile for react_on_rails.
         Do not use ^ or ~ in your package.json for react-on-rails.
         Run `yarn add react-on-rails --exact` in the directory containing folder node_modules.
         ***This warning will become a fatal error in ReactOnRails v15***
      MSG
    end

    def raise_differing_versions_warning
      msg = "**WARNING** ReactOnRails: ReactOnRails gem and node package versions do not match\n#{common_error_msg}"
      raise ReactOnRails::Error, msg
    end

    def raise_node_semver_version_warning
      msg = "**WARNING** ReactOnRails: Your node package version for react-on-rails contains a " \
            "^ or ~\n#{common_error_msg}"
      raise ReactOnRails::Error, msg
    end

    def log_differing_versions_warning
      msg = "**WARNING** ReactOnRails: ReactOnRails gem and node package versions do not match\n#{common_error_msg}"
      Rails.logger.warn(msg)
    end

    def log_node_semver_version_warning
      msg = "**WARNING** ReactOnRails: Your node package version for react-on-rails contains a " \
            "^ or ~\n#{common_error_msg}"
      Rails.logger.warn(msg)
    end

    def gem_version
      ReactOnRails::VERSION
    end

    def gem_major_minor_patch_version
      match = gem_version.match(MAJOR_MINOR_PATCH_VERSION_REGEX)
      [match[1], match[2], match[3]]
    end

    class NodePackageVersion
      attr_reader :package_json

      def self.build
        new(package_json_path)
      end

      def self.package_json_path(relative_path = "package.json")
        Rails.root.join(relative_path)
      end

      def initialize(package_json)
        @package_json = package_json
      end

      def raw
        return nil unless File.exist?(package_json)

        parsed_package_contents = JSON.parse(package_json_contents)
        if parsed_package_contents.key?("dependencies") &&
           parsed_package_contents["dependencies"].key?("react-on-rails")
          parsed_package_contents["dependencies"]["react-on-rails"]
        end
      end

      def semver_wildcard?
        raw.match(/[~^]/).present?
      end

      def relative_path?
        raw.match(/(\.\.|\Afile:)/).present?
      end

      def major_minor_patch
        return if relative_path?

        match = raw.match(MAJOR_MINOR_PATCH_VERSION_REGEX)
        unless match
          raise ReactOnRails::Error, "Cannot parse version number '#{raw}' (wildcard versions are not supported)"
        end

        [match[1], match[2], match[3]]
      end

      private

      def package_json_contents
        @package_json_contents ||= File.read(package_json)
      end
    end
  end
end

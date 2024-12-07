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
    def log_if_gem_and_node_package_versions_differ
      return if node_package_version.raw.nil? || node_package_version.relative_path?
      return log_node_semver_version_warning if node_package_version.semver_wildcard?

      node_major_minor_patch = node_package_version.major_minor_patch
      gem_major_minor_patch = gem_major_minor_patch_version
      versions_match = node_major_minor_patch[0] == gem_major_minor_patch[0] &&
                       node_major_minor_patch[1] == gem_major_minor_patch[1] &&
                       node_major_minor_patch[2] == gem_major_minor_patch[2]

      log_differing_versions_warning unless versions_match
    end

    private

    def common_error_msg
      <<-MSG.strip_heredoc
         Detected: #{node_package_version.raw}
              gem: #{gem_version}
         Ensure the installed version of the gem is the same as the version of
         your installed node package. Do not use >= or ~> in your Gemfile for react_on_rails.
         Do not use ^ or ~ in your package.json for react-on-rails.
         Run `yarn add react-on-rails --exact` in the directory containing folder node_modules.
      MSG
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

      def self.package_json_path
        Rails.root.join(ReactOnRails.configuration.node_modules_location, "package.json")
      end

      def initialize(package_json)
        @package_json = package_json
      end

      def raw
        if File.exist?(package_json)
          parsed_package_contents = JSON.parse(package_json_contents)
          if parsed_package_contents.key?("dependencies") &&
             parsed_package_contents["dependencies"].key?("react-on-rails")
            return parsed_package_contents["dependencies"]["react-on-rails"]
          end
        end
        msg = "No 'react-on-rails' entry in the dependencies of #{NodePackageVersion.package_json_path}, " \
              "which is the expected location according to ReactOnRails.configuration.node_modules_location"
        Rails.logger.warn(msg)
        nil
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

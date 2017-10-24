# frozen_string_literal: true

module ReactOnRails
  # Responsible for checking versions of rubygem versus yarn node package
  # against each otherat runtime.
  class VersionChecker
    attr_reader :node_package_version
    MAJOR_MINOR_PATCH_VERSION_REGEX = /(\d+)\.(\d+)\.(\d+)/

    def self.build
      new(NodePackageVersion.build)
    end

    def initialize(node_package_version)
      @node_package_version = node_package_version
    end

    # For compatibility, the gem and the node package versions should always match,
    # unless the user really knows what they're doing. So we will give a
    # warning if they do not.
    def raise_if_gem_and_node_package_versions_differ
      return if node_package_version.relative_path?
      node_major_minor_patch = node_package_version.major_minor_patch
      gem_major_minor_patch = gem_major_minor_patch_version
      return if node_major_minor_patch[0] == gem_major_minor_patch[0] &&
                node_major_minor_patch[1] == gem_major_minor_patch[1] &&
                node_major_minor_patch[2] == gem_major_minor_patch[2]

      raise_differing_versions_warning
    end

    private

    def raise_differing_versions_warning
      msg = "**ERROR** ReactOnRails: ReactOnRails gem and node package versions do not match\n" \
            "                     gem: #{gem_version}\n" \
            "            node package: #{node_package_version.raw}\n" \
            "Ensure the installed version of the gem is the same as the version of \n"\
            "your installed node package.\n"\
            "Run `#{ReactOnRails::Utils.prepend_cd_node_modules_directory('yarn add react-on-rails')}`"
      raise msg
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
        Rails.root.join("client", "package.json")
      end

      def initialize(package_json)
        @package_json = package_json
      end

      def raw
        parsed_package_contents = JSON.parse(package_json_contents)
        if parsed_package_contents.key?("dependencies") &&
           parsed_package_contents["dependencies"].key?("react-on-rails")
          parsed_package_contents["dependencies"]["react-on-rails"]
        else
          raise "no 'react-on-rails' entry in package.json dependencies"
        end
      end

      def relative_path?
        raw.match(%r{(\.\.|\Afile:///)}).present?
      end

      def major_minor_patch
        return if relative_path?
        match = raw.match(MAJOR_MINOR_PATCH_VERSION_REGEX)
        [match[1], match[2], match[3]]
      end

      private

      def package_json_contents
        @package_json_contents ||= File.read(package_json)
      end
    end
  end
end

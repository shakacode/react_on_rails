module ReactOnRails
  # Responsible for checking versions of rubygem versus yarn node package
  # against each otherat runtime.
  class VersionChecker
    attr_reader :node_package_version, :logger
    MAJOR_VERSION_REGEX = /(\d+)\.?/

    def self.build
      new(NodePackageVersion.build, Rails.logger)
    end

    def initialize(node_package_version, logger)
      @logger = logger
      @node_package_version = node_package_version
    end

    # For compatibility, the gem and the node package versions should always match,
    # unless the user really knows what they're doing. So we will give a
    # warning if they do not.
    def warn_if_gem_and_node_package_versions_differ
      return if node_package_version.relative_path?
      return if node_package_version.major == gem_major_version
      log_differing_versions_warning
    end

    private

    def log_differing_versions_warning
      msg = "**WARNING** ReactOnRails: ReactOnRails gem and node package MAJOR versions do not match\n" \
            "                     gem: #{gem_version}\n" \
            "            node package: #{node_package_version.raw}\n" \
            "Ensure the installed MAJOR version of the gem is the same as the MAJOR version of \n"\
            "your installed node package."
      logger.warn(msg)
    end

    def gem_version
      ReactOnRails::VERSION
    end

    def gem_major_version
      gem_version.match(MAJOR_VERSION_REGEX)[1]
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

      def major
        return if relative_path?
        raw.match(MAJOR_VERSION_REGEX)[1]
      end

      private

      def package_json_contents
        @package_json_contents ||= File.read(package_json)
      end
    end
  end
end

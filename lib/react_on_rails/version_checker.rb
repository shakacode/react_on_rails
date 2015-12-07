require_relative "version"

module ReactOnRails
  module VersionChecker
    # TODO: ROB
    # parse the client/package.json and ensure that either:
    # 1. version number matches
    # 2. version number is a relative path (for testing)
    # Throw error if not.
    # Allow skipping this check in the configuration in case somebody has a wacky configuration, such
    # as you don't know where their package.json

    # For compatibility, the gem and the node package versions should always match, unless the user
    # really knows what they're doing. So we will give a warning if they do not.
    def self.warn_if_gem_and_node_package_versions_differ
      return unless node_package_version_is_standard_version_number? &&
                    gem_version != node_package_version
      msg = "**WARNING** ReactOnRails: ReactOnRails gem and node package versions do not match\n" \
            "                     gem: #{gem_version}\n" \
            "            node package: #{node_package_version}\n" \
            "Ensure the installed version of the gem is the same as the version of your installed node package"
      puts(msg)
      Rails.logger.warn(msg)
    end

    private

    def self.gem_version
      ReactOnRails::VERSION
    end

    # Warning: we replace all hyphens with periods for normalization purposes
    def self.node_package_version
      return unless client_package_json.present? && File.exist?(client_package_json)
      contents = File.read(client_package_json)
      raw_version = contents.match(/"react-on-rails": "(.*)",/)[1]
      raw_version.tr("-", ".")
    end

    def self.client_package_json
      return unless Rails.root.present?
      Rails.root.join("client", "package.json")
    end

    # Basically this means "not a relative path" as we don't want warn the user
    # if they are purposely doing some wacky configuration.
    def self.node_package_version_is_standard_version_number?
      node_package_version =~ (/\d+\.\d+\.\d+(\..+\.\d+)?/)
    end
  end
end

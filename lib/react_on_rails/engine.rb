require_relative "version_checker"

module ReactOnRails
  class Engine < ::Rails::Engine
    config.to_prepare do
      if File.exist?(VersionChecker::NodePackageVersion.package_json_path)
        VersionChecker.build.warn_if_gem_and_node_package_versions_differ
      end
      ReactOnRails::ServerRenderingPool.reset_pool
    end
  end
end

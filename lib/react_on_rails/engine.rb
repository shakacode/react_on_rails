# frozen_string_literal: true

require "rails/railtie"

module ReactOnRails
  class Engine < ::Rails::Engine
    config.to_prepare do
      if File.exist?(VersionChecker::NodePackageVersion.package_json_path)
        VersionChecker.build.raise_if_gem_and_node_package_versions_differ
      end
      ReactOnRails::ServerRenderingPool.reset_pool
    end
  end
end

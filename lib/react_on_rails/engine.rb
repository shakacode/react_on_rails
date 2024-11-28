# frozen_string_literal: true

require "rails/railtie"

module ReactOnRails
  class Engine < ::Rails::Engine
    config.to_prepare do
      if VersionChecker.instance("package.json").raise_if_gem_and_node_package_versions_differ &&
         VersionChecker.instance("client/package.json").raise_if_gem_and_node_package_versions_differ
        Rails.logger.warn("No 'react-on-rails' entry found in 'dependencies' in package.json or client/package.json.")
      end
      ReactOnRails::ServerRenderingPool.reset_pool
    end
  end
end

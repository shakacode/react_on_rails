# frozen_string_literal: true

require "rails/railtie"

module ReactOnRails
  class Engine < ::Rails::Engine
    config.to_prepare do
      VersionChecker.build.log_if_gem_and_node_package_versions_differ
      ReactOnRails::ServerRenderingPool.reset_pool
    end

    # Rake tasks are automatically loaded from lib/tasks/*.rake by Rails::Engine
    # No need to explicitly load them here to avoid duplicate loading
  end
end

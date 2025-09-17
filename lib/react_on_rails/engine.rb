# frozen_string_literal: true

require "rails/railtie"

module ReactOnRails
  class Engine < ::Rails::Engine
    config.to_prepare do
      VersionChecker.build.log_if_gem_and_node_package_versions_differ
      ReactOnRails::ServerRenderingPool.reset_pool
    end

    rake_tasks do
      load File.expand_path("../tasks/generate_packs.rake", __dir__)
      load File.expand_path("../tasks/assets.rake", __dir__)
      load File.expand_path("../tasks/locale.rake", __dir__)
    end
  end
end

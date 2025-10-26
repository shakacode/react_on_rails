# frozen_string_literal: true

require "rails/railtie"

module ReactOnRails
  class Engine < ::Rails::Engine
    # Validate package versions and compatibility on Rails startup
    # This ensures the application fails fast if versions don't match or packages are misconfigured
    initializer "react_on_rails.validate_version_and_package_compatibility" do
      config.after_initialize do
        Rails.logger.info "[React on Rails] Validating package version and compatibility..."
        VersionChecker.build.validate_version_and_package_compatibility!
        Rails.logger.info "[React on Rails] Package validation successful"
      end
    end

    config.to_prepare do
      ReactOnRails::ServerRenderingPool.reset_pool
    end

    rake_tasks do
      load File.expand_path("../tasks/generate_packs.rake", __dir__)
      load File.expand_path("../tasks/assets.rake", __dir__)
      load File.expand_path("../tasks/locale.rake", __dir__)
    end
  end
end

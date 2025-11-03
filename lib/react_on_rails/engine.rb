# frozen_string_literal: true

require "rails/railtie"

module ReactOnRails
  class Engine < ::Rails::Engine
    # Validate package versions and compatibility on Rails startup
    # This ensures the application fails fast if versions don't match or packages are misconfigured
    # Skip validation during installation tasks (e.g., shakapacker:install, react_on_rails:install)
    initializer "react_on_rails.validate_version_and_package_compatibility" do
      config.after_initialize do
        # Skip validation if package.json doesn't exist yet (during initial setup)
        package_json = VersionChecker::NodePackageVersion.package_json_path
        next unless File.exist?(package_json)

        # Skip validation when generators explicitly set this flag (packages may not be installed yet)
        next if ENV["REACT_ON_RAILS_SKIP_VALIDATION"] == "true"

        # Skip validation if react-on-rails package is not installed yet (during generator run)
        # This allows generators to complete before the package is installed
        node_package_version = VersionChecker::NodePackageVersion.build
        has_base = node_package_version.react_on_rails_package?
        has_pro = node_package_version.react_on_rails_pro_package?
        next unless has_base || has_pro

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

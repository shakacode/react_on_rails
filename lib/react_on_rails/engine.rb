# frozen_string_literal: true

require "rails/railtie"

module ReactOnRails
  class Engine < ::Rails::Engine
    # Validate package versions and compatibility on Rails startup
    # This ensures the application fails fast if versions don't match or packages are misconfigured
    # Skip validation during installation tasks (e.g., shakapacker:install) or generator runtime
    initializer "react_on_rails.validate_version_and_package_compatibility" do
      config.after_initialize do
        next if skip_version_validation?

        Rails.logger.info "[React on Rails] Validating package version and compatibility..."
        VersionChecker.build.validate_version_and_package_compatibility!
        Rails.logger.info "[React on Rails] Package validation successful"
      end
    end

    # Determine if version validation should be skipped
    # @return [Boolean] true if validation should be skipped
    def self.skip_version_validation?
      # Check package.json first as it's cheaper and handles more cases
      if package_json_missing?
        Rails.logger.debug "[React on Rails] Skipping validation - package.json not found"
        return true
      end

      # Skip during generator runtime since packages are installed during execution
      if running_generator?
        Rails.logger.debug "[React on Rails] Skipping validation during generator runtime"
        return true
      end

      false
    end

    # Check if we're running a Rails generator
    # @return [Boolean] true if running a generator
    def self.running_generator?
      !ARGV.empty? && ARGV.first&.in?(%w[generate g])
    end

    # Check if package.json doesn't exist yet
    # @return [Boolean] true if package.json is missing
    def self.package_json_missing?
      !File.exist?(VersionChecker::NodePackageVersion.package_json_path)
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

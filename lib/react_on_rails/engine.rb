# frozen_string_literal: true

require "rails/railtie"

module ReactOnRails
  class Engine < ::Rails::Engine
    # Validate package versions and compatibility on Rails startup
    # This ensures the application fails fast if versions don't match or packages are misconfigured
    # Skip validation during installation tasks (e.g., shakapacker:install) or generator runtime
    initializer "react_on_rails.validate_version_and_package_compatibility" do
      config.after_initialize do
        next if Engine.skip_version_validation?

        Rails.logger.info "[React on Rails] Validating package version and compatibility..."
        VersionChecker.build.validate_version_and_package_compatibility!
        Rails.logger.info "[React on Rails] Package validation successful"
      end
    end

    # Determine if version validation should be skipped
    #
    # This method checks multiple conditions to determine if package version validation
    # should be skipped. Validation is skipped during setup scenarios where the npm
    # package isn't installed yet (e.g., during generator execution).
    #
    # @return [Boolean] true if validation should be skipped
    #
    # @note Thread Safety: ENV variables are process-global. In practice, Rails generators
    #   run in a single process, so concurrent execution is not a concern. If running
    #   generators concurrently (e.g., in parallel tests), ensure tests run in separate
    #   processes to avoid ENV variable conflicts.
    #
    # @example Testing with parallel processes
    #   # In RSpec configuration:
    #   config.before(:each) do |example|
    #     ENV.delete("REACT_ON_RAILS_SKIP_VALIDATION")
    #   end
    #
    # @note Manual ENV Setting: While this ENV variable is designed to be set by generators,
    #   users can manually set it (e.g., `REACT_ON_RAILS_SKIP_VALIDATION=true rails server`)
    #   to bypass validation. This should only be done temporarily during debugging or
    #   setup scenarios. The validation helps catch version mismatches early, so bypassing
    #   it in production is not recommended.
    def self.skip_version_validation?
      # Skip if explicitly disabled via environment variable (set by generators)
      # Using ENV variable instead of ARGV because Rails can modify/clear ARGV during
      # initialization, making ARGV unreliable for detecting generator context. The ENV
      # variable persists through the entire Rails initialization process.
      if ENV["REACT_ON_RAILS_SKIP_VALIDATION"] == "true"
        Rails.logger.debug "[React on Rails] Skipping validation - disabled via environment variable"
        return true
      end

      # Check package.json first as it's cheaper and handles more cases
      if package_json_missing?
        Rails.logger.debug "[React on Rails] Skipping validation - package.json not found"
        return true
      end

      # Skip during generator runtime since packages are installed during execution
      # This is a fallback check in case ENV wasn't set, though ENV is the primary mechanism
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

    # Rake tasks are automatically loaded from lib/tasks/*.rake by Rails::Engine
    # No need to explicitly load them here to avoid duplicate loading
  end
end

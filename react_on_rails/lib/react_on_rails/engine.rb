# frozen_string_literal: true

require "rails/railtie"

module ReactOnRails
  class Engine < ::Rails::Engine
    SHAKAPACKER_PACKAGE_MANAGER_CHECK = :error_unless_package_manager_is_obvious!
    SHAKAPACKER_MANAGER_GUARD_ISSUE_URL = "https://github.com/shakacode/react_on_rails/issues"

    # Suppress Shakapacker's packageManager guard when Shakapacker is not the configured bundler.
    #
    # Shakapacker ships a Rails::Engine whose `shakapacker.manager_checker` initializer raises
    # at boot if package.json lacks `packageManager` and a non-npm lockfile is present. That
    # initializer fires whenever Shakapacker is loaded, even as a transitive dependency of
    # React on Rails in a Vite-only / client-only setup that never adopts Shakapacker for builds.
    # See issue #3145.
    initializer "react_on_rails.suppress_shakapacker_package_manager_check",
                before: "shakapacker.manager_checker" do
      Engine.suppress_shakapacker_package_manager_check_if_not_bundler!
    end

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
    #
    # Heuristic: Rails::Generators is typically only defined during generator
    # commands. It could be defined by test helpers or gems that require
    # "rails/generators", but this is a fallback behind the ENV check above.
    def self.running_generator?
      defined?(Rails::Generators)
    end

    # Check if package.json doesn't exist yet
    # @return [Boolean] true if package.json is missing
    def self.package_json_missing?
      !File.exist?(VersionChecker::NodePackageVersion.package_json_path)
    end

    # Returns true when the host app has a Shakapacker config file, meaning Shakapacker
    # is the configured bundler. Returns false when Shakapacker is only present as a
    # transitive gem dependency (e.g., a Vite Rails app adopting React on Rails for
    # client-only mounts).
    def self.shakapacker_configured_as_bundler?
      Rails.root.join("config", "shakapacker.yml").exist?
    end

    # Wrap Shakapacker's package-manager guard when Shakapacker is not the bundler.
    # The wrapper checks config/shakapacker.yml at call time so the original guard still
    # runs if another app in the same process configures Shakapacker later.
    def self.suppress_shakapacker_package_manager_check_if_not_bundler!
      return if shakapacker_configured_as_bundler?

      manager = shakapacker_utils_manager
      return unless manager

      original_package_manager_check = shakapacker_package_manager_check(manager)
      return unless original_package_manager_check
      return if original_package_manager_check.source_location&.first == __FILE__

      Rails.logger&.info(
        "[React on Rails] No config/shakapacker.yml found; skipping Shakapacker " \
        "packageManager check (Shakapacker is loaded as a transitive dependency but " \
        "is not the configured bundler)."
      )

      manager.define_singleton_method(SHAKAPACKER_PACKAGE_MANAGER_CHECK) do
        # no-op while React on Rails detects Shakapacker is not the configured bundler.
        original_package_manager_check.call if ReactOnRails::Engine.shakapacker_configured_as_bundler?
      end
    end

    def self.shakapacker_utils_manager
      return ::Shakapacker::Utils::Manager if defined?(::Shakapacker::Utils::Manager)

      log_shakapacker_guard_warning("Shakapacker is loaded but ::Shakapacker::Utils::Manager is not defined.")
      nil
    end

    def self.shakapacker_package_manager_check(manager)
      return manager.method(SHAKAPACKER_PACKAGE_MANAGER_CHECK) if manager.respond_to?(SHAKAPACKER_PACKAGE_MANAGER_CHECK)

      log_shakapacker_guard_warning(
        "Shakapacker::Utils::Manager does not define #{SHAKAPACKER_PACKAGE_MANAGER_CHECK}."
      )
      nil
    end

    def self.log_shakapacker_guard_warning(message)
      Rails.logger&.warn(
        "[React on Rails] #{message} The packageManager guard suppression could not be applied. " \
        "If boot fails, please report this at #{SHAKAPACKER_MANAGER_GUARD_ISSUE_URL}"
      )
    end

    # Install ScoutApm instrumentation after ScoutApm is configured via "scout_apm.start" initializer.
    # https://github.com/scoutapp/scout_apm_ruby/blob/v6.1.0/lib/scout_apm.rb#L221
    initializer "react_on_rails.scout_apm_instrumentation", after: "scout_apm.start" do
      next unless defined?(ScoutApm)

      ReactOnRails::Helper.class_eval do
        include ScoutApm::Tracer
        instrument_method :react_component, type: "ReactOnRails", name: "react_component"
        instrument_method :react_component_hash, type: "ReactOnRails", name: "react_component_hash"
      end

      ReactOnRails::ServerRenderingPool::RubyEmbeddedJavaScript.singleton_class.class_eval do
        include ScoutApm::Tracer
        instrument_method :exec_server_render_js, type: "ReactOnRails", name: "ExecJs React Server Rendering"
      end
    end

    config.to_prepare do
      ReactOnRails::ServerRenderingPool.reset_pool
    end

    # Rake tasks are automatically loaded from lib/tasks/*.rake by Rails::Engine
    # No need to explicitly load them here to avoid duplicate loading
  end
end

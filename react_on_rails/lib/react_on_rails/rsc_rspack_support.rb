# frozen_string_literal: true

require "json"
require "open3"
require_relative "utils"

module ReactOnRails
  module RscRspackSupport
    RSC_RSPACK_PACKAGE = "@rspack/core"
    RSC_RSPACK_V2_PACKAGES = %w[
      @rspack/core
      @rspack/cli
      @rspack/dev-server
      @rspack/plugin-react-refresh
    ].freeze
    MINIMUM_RSC_RSPACK_MAJOR = 2
    DECLARED_PACKAGE_DEPENDENCY_FIELDS = %w[
      dependencies
      devDependencies
    ].freeze
    GENERIC_DECLARED_PACKAGE_DEPENDENCY_FIELDS = %w[
      devDependencies
      dependencies
    ].freeze
    RSC_RSPACK_PACKAGE_DEPENDENCY_FIELDS = [
      *DECLARED_PACKAGE_DEPENDENCY_FIELDS,
      "optionalDependencies"
    ].freeze
    RSC_RSPACK_UPGRADE_PACKAGE_DEPENDENCY_FIELDS = [
      *RSC_RSPACK_PACKAGE_DEPENDENCY_FIELDS,
      "peerDependencies"
    ].freeze
    PATH_PROTOCOL_PACKAGE_SPEC_PATTERN = /\A(?:file|link|portal):/
    PACKAGE_NAME_PATTERN = %r{
      \A
      (?:@[a-z0-9][a-z0-9._-]*/)?
      [a-z0-9][a-z0-9._-]*
      \z
    }x

    private

    def rsc_rspack_v2_install_command(package_json_path: nil)
      packages = rsc_rspack_upgrade_packages(package_json_path).map do |package_name|
        "#{package_name}@^#{MINIMUM_RSC_RSPACK_MAJOR}"
      end.join(" ")

      case rsc_detected_package_manager
      when :pnpm
        "pnpm add -D #{packages}"
      when :bun
        "bun add --dev #{packages}"
      when :npm
        "npm install --save-dev #{packages}"
      else
        "yarn add --dev #{packages}"
      end
    end

    def rsc_rspack_version_requirement_error(
      rspack_version,
      error_prefix: nil,
      include_doctor_recommendation: false,
      package_json_path: nil
    )
      detected_version = rspack_version || "not found"
      prefix = "#{error_prefix} " if error_prefix
      doctor_recommendation = "\n\n#{ReactOnRails::DOCTOR_RECOMMENDATION}" if include_doctor_recommendation

      <<~MSG.strip
        #{prefix}RSC with Rspack requires Rspack v2 or newer.

        Detected #{RSC_RSPACK_PACKAGE}: #{detected_version}

        Rspack v1 is not supported for React Server Components in React on Rails Pro.
        Upgrade to Rspack v2 to ensure RSC works correctly instead of hitting bundler or runtime surprises.
        If #{RSC_RSPACK_PACKAGE} is declared with an npm range, dist-tag, workspace spec, or local path that
        React on Rails cannot statically verify, install dependencies so Node can resolve the installed package
        version or pin #{RSC_RSPACK_PACKAGE} to Rspack v2.

        Fix:
          #{rsc_rspack_v2_install_command(package_json_path:)}#{doctor_recommendation}
      MSG
    end

    def rsc_installed_package_version(package_root, package_name, &)
      version = rsc_installed_package_json(package_root, package_name, &)&.fetch("version", nil)
      version if version&.match?(/\A\d+\.\d+\.\d+/)
    end

    def rsc_flat_installed_package_version(package_root, package_name)
      version = rsc_flat_installed_package_json(package_root, package_name)&.fetch("version", nil)
      version if version&.match?(/\A\d+\.\d+\.\d+/)
    end

    def rsc_installed_package_json(package_root, package_name, &)
      return nil unless valid_rsc_package_name?(package_name)

      script = "console.log(require.resolve(process.argv[1] + '/package.json'))"
      resolved_path = rsc_resolved_node_package_json_path(package_root, package_name, script, &)
      # package_name has passed PACKAGE_NAME_PATTERN, so this fallback cannot escape node_modules.
      # It covers classic flat node_modules layouts; pnpm virtual-store layouts rely on Node resolution above.
      # Limitation: a stale orphaned directory can still be read if Node resolution fails.
      resolved_path = rsc_flat_installed_package_json_path(package_root, package_name) if resolved_path.empty?
      return nil unless File.exist?(resolved_path)

      JSON.parse(File.read(resolved_path))
    rescue StandardError
      nil
    end

    def rsc_flat_installed_package_json(package_root, package_name)
      return nil unless valid_rsc_package_name?(package_name)

      package_json_path = rsc_flat_installed_package_json_path(package_root, package_name)
      return nil unless File.exist?(package_json_path)

      JSON.parse(File.read(package_json_path))
    rescue StandardError
      nil
    end

    def rsc_flat_installed_package_json_path(package_root, package_name)
      File.join(package_root, "node_modules", package_name, "package.json")
    end

    def rsc_support_enabled_config_value
      return false unless ReactOnRails::Utils.react_on_rails_pro?
      return false unless defined?(ReactOnRailsPro) && ReactOnRailsPro.respond_to?(:configuration)

      pro_config = ReactOnRailsPro.configuration
      pro_config.respond_to?(:enable_rsc_support) && pro_config.enable_rsc_support
    end

    def rsc_declared_package_spec(package_json_path, package_name)
      package_json = JSON.parse(File.read(package_json_path))
      rsc_package_dependency_spec(package_json, package_name)
    rescue StandardError
      nil
    end

    def rsc_declared_package_version(package_json_path, package_name)
      package_spec = rsc_declared_package_spec(package_json_path, package_name)
      rsc_normalized_declared_package_version(package_spec) || package_spec
    end

    def rsc_package_major_version(version)
      version_string = version.to_s
      normalized_version = rsc_normalized_declared_package_version(version_string)
      return normalized_version.split(".").first.to_i if normalized_version

      # Path-based protocol specs cannot be statically verified; reject them unless Node resolution found v2.
      return 0 if version_string.match?(PATH_PROTOCOL_PACKAGE_SPEC_PATTERN)
      return 0 if version_string.include?("/") && !version_string.start_with?("npm:")
      return 0 if version_string.start_with?("workspace:")

      # Accept installed semver versions and simple declared lower-bound specs. Other npm ranges or dist-tags
      # fail closed unless Node resolution already proved that the installed package is Rspack v2.
      major = version_string.match(/\Av?(\d+)\.\d+\.\d+(?:[-+].*)?\z/)&.[](1)
      major.to_i
    end

    def rsc_resolved_node_package_json_path(package_root, package_name, script, &)
      # Boot/doctor validation only. This is intentionally outside the request path.
      stdout, _stderr, status = Open3.capture3("node", "-e", script, package_name, chdir: package_root)
      unless status.success?
        yield(package_name) if block_given?
        return ""
      end

      stdout.strip
    rescue StandardError
      yield(package_name) if block_given?
      ""
    end

    def rsc_detected_package_manager
      ReactOnRails::Utils.detect_package_manager
    rescue StandardError
      :yarn
    end

    def valid_rsc_package_name?(package_name)
      package_name.to_s.match?(PACKAGE_NAME_PATTERN)
    end

    def rsc_package_dependency_spec(package_json, package_name, fields: RSC_RSPACK_PACKAGE_DEPENDENCY_FIELDS)
      # The default is Rspack-specific; generic package checks pass stricter dependency fields.
      fields.each do |field|
        spec = package_json.fetch(field, nil)&.fetch(package_name, nil)
        return spec if spec
      end

      nil
    end

    def rsc_normalized_declared_package_version(package_spec)
      spec = package_spec.to_s.strip
      return nil if spec.match?(PATH_PROTOCOL_PACKAGE_SPEC_PATTERN)
      return nil if spec.start_with?("workspace:")

      spec = spec.sub(%r{\Anpm:(?:@[^/]+/)?[^@]+@}, "")
      spec.match(/\A(?:[~^]|>=?|=)?\s*v?(\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?)\z/)&.[](1)
    end

    def rsc_rspack_upgrade_packages(package_json_path)
      declared_packages = rsc_declared_rspack_upgrade_packages(package_json_path)
      # If package.json cannot be read, suggest the full Rspack v2 suite so generated Rspack apps get all
      # companion packages needed by the standard React on Rails development workflow.
      return RSC_RSPACK_V2_PACKAGES if declared_packages.empty?
      return declared_packages if declared_packages.include?(RSC_RSPACK_PACKAGE)

      [RSC_RSPACK_PACKAGE, *declared_packages]
    end

    def rsc_declared_rspack_upgrade_packages(package_json_path)
      return [] if package_json_path.to_s.empty?

      package_json = JSON.parse(File.read(package_json_path))
      RSC_RSPACK_V2_PACKAGES.select do |package_name|
        rsc_package_dependency_spec(
          package_json,
          package_name,
          fields: RSC_RSPACK_UPGRADE_PACKAGE_DEPENDENCY_FIELDS
        )
      end
    rescue StandardError
      []
    end
  end
end

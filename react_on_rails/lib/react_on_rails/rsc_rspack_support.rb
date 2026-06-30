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
    PACKAGE_DEPENDENCY_FIELDS = %w[
      dependencies
      devDependencies
      optionalDependencies
    ].freeze
    PACKAGE_NAME_PATTERN = %r{
      \A
      (?:@[a-z0-9][a-z0-9._-]*/)?
      [a-z0-9][a-z0-9._-]*
      \z
    }x

    private

    def rsc_rspack_v2_install_command
      packages = RSC_RSPACK_V2_PACKAGES.map do |package_name|
        "#{package_name}@^#{MINIMUM_RSC_RSPACK_MAJOR}"
      end.join(" ")

      case ReactOnRails::Utils.detect_package_manager
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

    def rsc_rspack_version_requirement_error(rspack_version, error_prefix: nil, include_doctor_recommendation: false)
      detected_version = rspack_version || "not found"
      prefix = "#{error_prefix} " if error_prefix
      doctor_recommendation = "\n\n#{ReactOnRails::DOCTOR_RECOMMENDATION}" if include_doctor_recommendation

      <<~MSG.strip
        #{prefix}RSC with Rspack requires Rspack v2 or newer.

        Detected #{RSC_RSPACK_PACKAGE}: #{detected_version}

        Rspack v1 is not supported for React Server Components in React on Rails Pro.
        Upgrade to Rspack v2 so RSC setup fails fast instead of hitting bundler or runtime surprises.

        Fix:
          #{rsc_rspack_v2_install_command}#{doctor_recommendation}
      MSG
    end

    def rsc_installed_package_version(package_root, package_name, &)
      version = rsc_installed_package_json(package_root, package_name, &)&.fetch("version", nil)
      version if version&.match?(/\A\d+\.\d+\.\d+/)
    end

    def rsc_installed_package_json(package_root, package_name, &)
      return nil unless valid_rsc_package_name?(package_name)

      script = "console.log(require.resolve(process.argv[1] + '/package.json'))"
      resolved_path = rsc_resolved_node_package_json_path(package_root, package_name, script, &)
      # package_name has passed PACKAGE_NAME_PATTERN, so this fallback cannot escape node_modules.
      # It covers classic flat node_modules layouts; pnpm virtual-store layouts rely on Node resolution above.
      # Limitation: a stale orphaned directory can still be read if Node resolution fails.
      resolved_path = File.join(package_root, "node_modules", package_name, "package.json") if resolved_path.empty?
      return nil if resolved_path.empty? || !File.exist?(resolved_path)

      JSON.parse(File.read(resolved_path))
    rescue StandardError
      nil
    end

    def rsc_declared_package_spec(package_json_path, package_name)
      package_json = JSON.parse(File.read(package_json_path))
      rsc_package_dependency_spec(package_json, package_name)
    rescue JSON::ParserError, Errno::ENOENT
      nil
    end

    def rsc_package_major_version(version)
      version_string = version.to_s
      return 0 if version_string.include?("/") && !version_string.start_with?("npm:")

      version_without_alias = version_string.sub(%r{\Anpm:(?:@[^/]+/)?[^@]+@}, "")
      major = version_without_alias.match(/\d+/)&.[](0)
      major.to_i
    end

    def rsc_resolved_node_package_json_path(package_root, package_name, script)
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

    def valid_rsc_package_name?(package_name)
      package_name.to_s.match?(PACKAGE_NAME_PATTERN)
    end

    def rsc_package_dependency_spec(package_json, package_name)
      PACKAGE_DEPENDENCY_FIELDS.each do |field|
        spec = package_json.fetch(field, nil)&.fetch(package_name, nil)
        return spec if spec
      end

      nil
    end
  end
end

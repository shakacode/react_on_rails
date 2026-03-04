# frozen_string_literal: true

module ReactOnRails
  class LicenseScanner
    DISALLOWED_LICENSES = %w[
      GPL-2.0
      GPL-2.0-only
      GPL-2.0-or-later
      GPL-3.0
      GPL-3.0-only
      GPL-3.0-or-later
      AGPL-3.0
      AGPL-3.0-only
      AGPL-3.0-or-later
    ].freeze

    PERMISSIVE_LICENSES = %w[
      MIT
      Apache-2.0
      BSD-2-Clause
      BSD-3-Clause
      ISC
      Ruby
      Artistic-2.0
      0BSD
      Unlicense
      CC0-1.0
      Zlib
      BSL-1.0
      PostgreSQL
      BlueOak-1.0.0
    ].freeze

    Result = Struct.new(:violations, :warnings, :scanned_count, keyword_init: true)
    Violation = Struct.new(:name, :version, :licenses, :source, keyword_init: true)

    def initialize
      @violations = []
      @warnings = []
      @scanned_count = 0
    end

    def scan
      scan_ruby_gems
      scan_js_packages
      Result.new(violations: @violations, warnings: @warnings, scanned_count: @scanned_count)
    end

    private

    def scan_ruby_gems
      require "bundler"

      Bundler.definition.resolve.each do |spec|
        full_spec = begin
          Gem::Specification.find_by_name(spec.name, spec.version.to_s)
        rescue Gem::MissingSpecError
          nil
        end

        next unless full_spec

        licenses = full_spec.licenses
        licenses = [full_spec.license || "unknown"] if licenses.empty?

        @scanned_count += 1
        check_licenses(spec.name, spec.version.to_s, licenses, "rubygem")
      end
    end

    def scan_js_packages
      lockfile = find_js_lockfile
      return unless lockfile

      package_manager = detect_package_manager(lockfile)
      licenses_json = fetch_js_licenses(package_manager)
      return if licenses_json.nil?

      parse_js_licenses(licenses_json, package_manager)
    end

    def find_js_lockfile
      root = defined?(Rails) && Rails.root ? Rails.root : Pathname.new(Dir.pwd)
      %w[pnpm-lock.yaml yarn.lock package-lock.json].each do |lockfile|
        path = root.join(lockfile)
        return path if path.exist?
      end
      nil
    end

    LOCKFILE_MANAGERS = {
      "pnpm-lock.yaml" => :pnpm,
      "yarn.lock" => :yarn,
      "package-lock.json" => :npm
    }.freeze

    LICENSE_COMMANDS = {
      pnpm: "pnpm licenses list --json 2>/dev/null",
      yarn: "yarn licenses list --json --no-progress 2>/dev/null",
      npm: "npx license-checker --json 2>/dev/null"
    }.freeze

    def detect_package_manager(lockfile)
      LOCKFILE_MANAGERS[lockfile.basename.to_s]
    end

    def fetch_js_licenses(package_manager)
      cmd = LICENSE_COMMANDS[package_manager]

      output = `#{cmd}`
      return nil unless $CHILD_STATUS&.success?

      require "json"
      JSON.parse(output)
    rescue JSON::ParserError
      nil
    end

    def parse_js_licenses(data, package_manager)
      case package_manager
      when :pnpm
        parse_pnpm_licenses(data)
      when :npm
        parse_npm_licenses(data)
      when :yarn
        parse_yarn_licenses(data)
      end
    end

    def parse_pnpm_licenses(data)
      # pnpm groups by license: { "MIT": [{ "name": "pkg", "versions": ["1.0"] }, ...] }
      data.each do |license, packages|
        Array(packages).each do |entry|
          version = Array(entry["versions"]).first
          @scanned_count += 1
          check_licenses(entry["name"], version, [license.to_s], "npm")
        end
      end
    end

    def parse_npm_licenses(data)
      data.each do |key, info|
        name, version = key.rpartition("@").then { |n, _, v| [n, v] }
        @scanned_count += 1
        check_licenses(name, version, Array(info["licenses"] || "unknown"), "npm")
      end
    end

    def parse_yarn_licenses(data)
      return unless data.is_a?(Hash) && data["data"]

      (data.dig("data", "body") || []).each do |entry|
        @scanned_count += 1
        check_licenses(entry[0], entry[1], [entry[2] || "unknown"], "npm")
      end
    end

    def check_licenses(name, version, licenses, source)
      normalized = licenses.map { |l| normalize_license(l) }

      disallowed = normalized.select { |l| disallowed_license?(l) }
      return if disallowed.empty?

      has_permissive = normalized.any? { |l| permissive_license?(l) }
      if has_permissive
        @warnings << Violation.new(name: name, version: version, licenses: licenses, source: source)
      else
        @violations << Violation.new(name: name, version: version, licenses: licenses, source: source)
      end
    end

    def normalize_license(license)
      license.to_s.strip
    end

    def disallowed_license?(license)
      DISALLOWED_LICENSES.any? { |d| license.start_with?(d) || license.casecmp(d).zero? }
    end

    def permissive_license?(license)
      PERMISSIVE_LICENSES.any? { |p| license.casecmp(p).zero? }
    end
  end
end

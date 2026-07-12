# frozen_string_literal: true

module ReactOnRails
  # Public contract for the machine-readable doctor report.
  #
  # Check IDs are stable identifiers for automation. Never rename or reuse one;
  # add a new ID for a new check. Additive fields may be introduced without a
  # schema version bump, but removing or changing a documented field requires a
  # new version.
  module DoctorSchema
    VERSION = 1
    STATUSES = %w[pass warn fail].freeze
    SEVERITIES = %w[info warning error].freeze
    STATUS_SEVERITIES = { "pass" => "info", "warn" => "warning", "fail" => "error" }.freeze
    DETAIL_LEVELS = %w[success warning error info].freeze
    EXIT_CODES = { pass: 0, warn: 0, fail: 1 }.freeze
    DOCS_URL = "https://reactonrails.com/docs/api-reference/doctor"

    CHECK_METADATA = {
      "environment_prerequisites" => {
        files: ["package.json", "package manager lockfile"],
        expected_end_state: "Node.js and the app's JavaScript package manager are installed and detected."
      },
      "react_on_rails_versions" => {
        files: ["Gemfile", "package.json", "package manager lockfile"],
        expected_end_state: "The React on Rails gem and npm package versions are compatible and pinned safely."
      },
      "react_on_rails_packages" => {
        files: ["Gemfile", "config/shakapacker.yml", "config/webpack", "config/rspack"],
        expected_end_state: "Shakapacker is installed and its configured bundler files exist."
      },
      "javascript_package_dependencies" => {
        files: ["package.json", "package manager lockfile"],
        expected_end_state: "Required React and React on Rails JavaScript dependencies are installed and compatible."
      },
      "key_configuration_files" => {
        files: ["config/initializers/react_on_rails.rb", "config/shakapacker.yml", "app/javascript"],
        expected_end_state: "The generated React on Rails configuration files exist and match the app setup."
      },
      "configuration_analysis" => {
        files: ["config/initializers/react_on_rails.rb", "config/shakapacker.yml", "app/views/layouts"],
        expected_end_state: "React on Rails, Shakapacker, and server bundle settings agree."
      },
      "bin_dev_launcher_setup" => {
        files: ["bin/dev", "Procfile.dev", "Procfile.dev-static-assets"],
        expected_end_state: "The development launcher starts Rails and the configured asset bundler correctly."
      },
      "rails_integration" => {
        files: ["config/initializers/react_on_rails.rb", "config/application.rb"],
        expected_end_state: "Rails loads the React on Rails initializer successfully."
      },
      "bundler_configuration" => {
        files: ["config/shakapacker.yml", "config/webpack", "config/rspack"],
        expected_end_state: "The configured webpack or Rspack entry point is present and valid."
      },
      "testing_setup" => {
        files: ["spec/rails_helper.rb", "spec/spec_helper.rb", "test/test_helper.rb"],
        expected_end_state: "The test suite builds React assets before tests that need them."
      },
      "development_environment" => {
        files: ["config/environments/development.rb", "config/shakapacker.yml", "package.json"],
        expected_end_state: "The development server, HMR, and generated bundle settings are consistent."
      },
      "react_on_rails_pro_setup" => {
        files: ["Gemfile", "package.json", "config/initializers/react_on_rails.rb"],
        expected_end_state: "React on Rails Pro packages and configuration are mutually compatible."
      },
      "react_server_components" => {
        files: ["config/initializers/react_on_rails.rb", "config/shakapacker.yml", "app/javascript"],
        expected_end_state: "RSC packages, generated artifacts, and renderer configuration are consistent."
      }
    }.freeze

    module_function

    def metadata(check_id)
      CHECK_METADATA.fetch(check_id)
    end

    def docs_url(check_id)
      "#{DOCS_URL}#check-id-#{check_id.tr('_', '-')}"
    end

    # Runtime validation keeps the emitted payload aligned with the documented
    # contract without adding a runtime JSON-schema dependency to the gem.
    def validate!(report)
      required_keys!(report, %i[schema_version ror_version status checks summary], "report")
      assert(report[:schema_version] == VERSION, "unsupported schema_version")
      assert(report[:ror_version].is_a?(String), "ror_version must be a string")
      assert(STATUSES.include?(report[:status]), "invalid report status")
      assert(report[:checks].is_a?(Array), "checks must be an array")
      report[:checks].each { |check| validate_check!(check) }
      validate_unique_check_ids!(report[:checks])
      validate_summary!(report)
      report
    end

    def validate_check!(check)
      required_keys!(check, %i[id title status severity message fix_command docs_url remediation details], "check")
      assert(CHECK_METADATA.key?(check[:id]), "unknown check id #{check[:id].inspect}")
      assert(STATUSES.include?(check[:status]), "invalid status for #{check[:id]}")
      assert(SEVERITIES.include?(check[:severity]), "invalid severity for #{check[:id]}")
      assert(check[:severity] == STATUS_SEVERITIES[check[:status]], "severity does not match status for #{check[:id]}")
      validate_check_field_types!(check)
      validate_details!(check)
      validate_remediation!(check)
    end

    def validate_check_field_types!(check)
      assert(check[:title].is_a?(String), "invalid title for #{check[:id]}")
      assert(check[:message].nil? || check[:message].is_a?(String), "invalid message for #{check[:id]}")
      assert(check[:fix_command].nil? || check[:fix_command].is_a?(String), "invalid fix_command for #{check[:id]}")
      assert(check[:docs_url].is_a?(String), "invalid docs_url for #{check[:id]}")
    end

    def validate_details!(check)
      assert(check[:details].is_a?(Array), "details must be an array for #{check[:id]}")
      check[:details].each { |detail| validate_detail!(detail, check[:id]) }
    end

    def validate_detail!(detail, check_id)
      required_keys!(detail, %i[level content], "detail for #{check_id}")
      assert(DETAIL_LEVELS.include?(detail[:level]), "invalid detail level for #{check_id}")
      assert(detail[:content].is_a?(String), "invalid detail content for #{check_id}")
    end

    def validate_remediation!(check)
      remediation = check[:remediation]
      if check[:status] == "pass"
        assert(remediation.nil?, "passing check #{check[:id]} must not have remediation")
        return
      end

      assert(remediation.is_a?(Hash), "non-passing check #{check[:id]} must have remediation")
      required_keys!(remediation, %i[prompt files expected_end_state], "remediation")
      assert(remediation[:prompt].is_a?(String) && !remediation[:prompt].empty?, "invalid remediation prompt")
      assert(remediation[:files].is_a?(Array) && remediation[:files].all?(String), "invalid remediation files")
      assert(remediation[:expected_end_state].is_a?(String), "invalid remediation expected_end_state")
    end

    def validate_unique_check_ids!(checks)
      ids = checks.map { |check| check[:id] }
      assert(ids.uniq.length == ids.length, "check ids must be unique")
    end

    def validate_summary!(report)
      summary = report[:summary]
      required_keys!(summary, %i[pass warn fail], "summary")
      assert(summary.values.all? { |count| count.is_a?(Integer) && count >= 0 },
             "summary values must be non-negative integers")

      statuses = report[:checks].map { |check| check[:status] }
      expected_summary = { pass: statuses.count("pass"), warn: statuses.count("warn"), fail: statuses.count("fail") }
      assert(summary == expected_summary, "summary does not match checks")
      assert(report[:status] == overall_status(statuses), "report status does not match checks")
    end

    def overall_status(statuses)
      return "fail" if statuses.include?("fail")
      return "warn" if statuses.include?("warn")

      "pass"
    end

    def required_keys!(value, keys, label)
      assert(value.is_a?(Hash), "#{label} must be an object")
      missing = keys - value.keys
      assert(missing.empty?, "#{label} missing keys: #{missing.join(', ')}")
    end

    def assert(condition, message)
      raise ArgumentError, "Invalid doctor JSON report: #{message}" unless condition
    end
  end
end

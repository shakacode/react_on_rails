# frozen_string_literal: true

require "json"
require "rainbow"

module GeneratorMessages
  module CiSection
    private

    def build_ci_section(app_root: Dir.pwd, ci_workflow_generated: false)
      return "" unless ci_workflow_generated || File.exist?(File.join(app_root, ".github/workflows/ci.yml"))

      package_manager = detect_package_manager(app_root: app_root)
      ci_status = if ci_workflow_generated
                    "A GitHub Actions workflow has been generated at .github/workflows/ci.yml."
                  else
                    "A GitHub Actions workflow is available at .github/workflows/ci.yml."
                  end

      build_test_hint = if package_json_has_script?(app_root, "build:test")
                          "\n\nOr use the generated package.json script:\n" \
                            "#{Rainbow("#{package_manager} run build:test").cyan}"
                        else
                          ""
                        end

      <<~CI


        🔄 CI / BUILD ORDERING:
        ─────────────────────────────────────────────────────────────────────────
        JavaScript bundles must be built before running Rails tests.
        #{ci_status}

        To build bundles manually before tests:
        #{Rainbow('RAILS_ENV=test NODE_ENV=test bin/shakapacker').cyan}#{build_test_hint}
      CI
    end

    def package_json_has_script?(app_root, script_name)
      package_json_path = File.join(app_root, "package.json")
      return false unless File.exist?(package_json_path)

      content = JSON.parse(File.read(package_json_path))
      content.dig("scripts", script_name) ? true : false
    rescue JSON::ParserError, Errno::EACCES, Errno::ENOENT
      false
    end
  end
end

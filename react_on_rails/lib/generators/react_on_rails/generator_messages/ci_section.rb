# frozen_string_literal: true

require "rainbow"

module GeneratorMessages
  module CiSection
    private

    def build_ci_section(app_root: Dir.pwd, ci_workflow_generated: false)
      return "" unless ci_workflow_generated || File.exist?(File.join(app_root, ".github/workflows/ci.yml"))

      # Read package.json once and reuse for both package-manager detection and the
      # build:test script presence check to avoid a second I/O pass.
      package_json = read_package_json(app_root)
      package_manager = detect_package_manager(app_root: app_root, package_json: package_json)
      ci_status = if ci_workflow_generated
                    "A GitHub Actions workflow has been generated at .github/workflows/ci.yml."
                  else
                    "A GitHub Actions workflow is available at .github/workflows/ci.yml."
                  end

      build_test_hint = if package_json&.dig("scripts", "build:test")
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
  end
end

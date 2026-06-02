# frozen_string_literal: true

require "rainbow"

module GeneratorMessages
  module CiSection
    DEFAULT_PRECOMPILE_HOOK_COMMAND = "bin/shakapacker-precompile-hook"
    private_constant :DEFAULT_PRECOMPILE_HOOK_COMMAND

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
      manual_build_command = shakapacker_build_command(
        env: "RAILS_ENV=test NODE_ENV=test",
        app_root: app_root,
        environment: "test"
      )

      <<~CI


        🔄 CI / BUILD ORDERING:
        ─────────────────────────────────────────────────────────────────────────
        JavaScript bundles must be built before running Rails tests.
        #{ci_status}

        To build bundles manually before tests:
        #{Rainbow(manual_build_command).cyan}#{build_test_hint}
      CI
    end

    def shakapacker_build_command(env:, app_root:, environment:)
      hook_command = shakapacker_precompile_hook_command(app_root: app_root, environment: environment)
      shakapacker_command = "#{env} bin/shakapacker"
      return shakapacker_command unless hook_command

      "#{env} #{hook_command} && SHAKAPACKER_SKIP_PRECOMPILE_HOOK=true #{shakapacker_command}"
    end

    def shakapacker_precompile_hook_command(app_root:, environment:)
      shakapacker_config_path = File.join(app_root, "config/shakapacker.yml")
      return DEFAULT_PRECOMPILE_HOOK_COMMAND unless File.exist?(shakapacker_config_path)

      config = parse_shakapacker_yml(shakapacker_config_path)
      hook_command = normalize_precompile_hook(effective_precompile_hook(config, environment))

      # Custom hooks stay inside Shakapacker so direct commands don't double-run on older supported versions.
      generated_precompile_hook?(hook_command) ? hook_command : nil
    end

    def effective_precompile_hook(config, environment)
      environment_section = shakapacker_config_section(config, environment)
      unless shakapacker_config_key?(config, environment)
        environment_section = shakapacker_config_section(config, "production")
      end

      shakapacker_config_value(environment_section, "precompile_hook")
    end

    def shakapacker_config_section(config, section)
      return {} unless config.respond_to?(:fetch)

      section_config = config.fetch(section, config.fetch(section.to_sym, {}))
      section_config.respond_to?(:key?) ? section_config : {}
    end

    def shakapacker_config_key?(section, key)
      return false unless section.respond_to?(:key?)

      section.key?(key) || section.key?(key.to_sym)
    end

    def shakapacker_config_value(section, key)
      return section[key] if section.key?(key)
      return section[key.to_sym] if section.key?(key.to_sym)

      nil
    end

    def normalize_precompile_hook(hook)
      return nil if hook.nil? || hook == false || hook.to_s.empty?

      hook.to_s.strip
    end

    def generated_precompile_hook?(hook_command)
      hook_command == DEFAULT_PRECOMPILE_HOOK_COMMAND
    end

    def parse_shakapacker_yml(path)
      require "yaml"

      YAML.safe_load_file(path, permitted_classes: [Symbol], aliases: true)
    rescue ArgumentError
      begin
        YAML.safe_load_file(path, permitted_classes: [Symbol])
      rescue ArgumentError
        YAML.safe_load(File.read(path), permitted_classes: [Symbol]) # rubocop:disable Style/YAMLFileRead
      end
    rescue StandardError
      {}
    end
  end
end

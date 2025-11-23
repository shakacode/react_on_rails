# frozen_string_literal: true

require "yaml"
require "English"
require "rainbow"

module ReactOnRails
  module Dev
    # ServiceChecker validates that required external services are running
    # before starting the development server.
    #
    # Configuration is read from .dev-services.yml in the app root:
    #
    # services:
    #   redis:
    #     check_command: "redis-cli ping"
    #     expected_output: "PONG"
    #     start_command: "redis-server"
    #     description: "Redis (for caching and background jobs)"
    #   postgresql:
    #     check_command: "pg_isready"
    #     expected_output: "accepting connections"
    #     start_command: "pg_ctl -D /usr/local/var/postgres start"
    #     description: "PostgreSQL database"
    #
    class ServiceChecker
      # Configuration file keys
      CONFIG_KEYS = {
        services: "services",
        check_command: "check_command",
        expected_output: "expected_output",
        start_command: "start_command",
        install_hint: "install_hint",
        description: "description"
      }.freeze

      class << self
        # Check all required services and provide helpful output
        #
        # @param config_path [String] Path to .dev-services.yml (default: ./.dev-services.yml)
        # @return [Boolean] true if all services are running or no config exists
        def check_services(config_path: ".dev-services.yml")
          return true unless File.exist?(config_path)

          config = load_config(config_path)
          return true unless config_has_services?(config)

          check_and_report_services(config, config_path)
        end

        private

        def config_has_services?(config)
          config && config[CONFIG_KEYS[:services]] && !config[CONFIG_KEYS[:services]].empty?
        end

        def check_and_report_services(config, config_path)
          print_services_header(config_path)

          failures = collect_service_failures(config[CONFIG_KEYS[:services]])

          report_results(failures)
        end

        def collect_service_failures(services)
          failures = []

          services.each do |name, service_config|
            if check_service(name, service_config)
              print_service_ok(name, service_config[CONFIG_KEYS[:description]])
            else
              failures << { name: name, config: service_config }
              print_service_failed(name, service_config[CONFIG_KEYS[:description]])
            end
          end

          failures
        end

        def report_results(failures)
          if failures.empty?
            print_all_services_ok
            true
          else
            print_failures_summary(failures)
            false
          end
        end

        def load_config(config_path)
          YAML.load_file(config_path)
        rescue StandardError => e
          puts Rainbow("⚠️  Failed to load #{config_path}: #{e.message}").yellow
          puts Rainbow("   Continuing without service checks...").yellow
          puts ""
          nil
        end

        def check_service(_name, config)
          check_command = config[CONFIG_KEYS[:check_command]]
          expected_output = config[CONFIG_KEYS[:expected_output]]

          return false if check_command.nil?

          output, status = run_check_command(check_command)

          return false if status.nil?

          return status.success? if expected_output.nil?

          status.success? && output.include?(expected_output)
        end

        def run_check_command(command)
          require "open3"
          stdout, stderr, status = Open3.capture3(command, err: %i[child out])
          output = stdout + stderr
          [output, status]
        rescue Errno::ENOENT
          # Command not found - service is not available
          ["", nil]
        rescue StandardError => e
          # Log unexpected errors for debugging
          warn "Unexpected error checking service: #{e.message}" if ENV["DEBUG"]
          ["", nil]
        end

        def print_services_header(config_path)
          puts ""
          puts Rainbow("🔍 Checking required services (#{config_path})...").cyan.bold
          puts ""
        end

        def print_service_ok(name, description)
          desc = description ? " - #{description}" : ""
          puts "   #{Rainbow('✓').green} #{name}#{desc}"
        end

        def print_service_failed(name, description)
          desc = description ? " - #{description}" : ""
          puts "   #{Rainbow('✗').red} #{name}#{desc}"
        end

        def print_all_services_ok
          puts ""
          puts Rainbow("✅ All services are running").green.bold
          puts ""
        end

        # rubocop:disable Metrics/AbcSize
        def print_failures_summary(failures)
          puts ""
          puts Rainbow("❌ Some services are not running").red.bold
          puts ""
          puts Rainbow("Please start these services before running bin/dev:").yellow
          puts ""

          failures.each do |failure|
            name = failure[:name]
            config = failure[:config]
            description = config[CONFIG_KEYS[:description]] || name

            puts Rainbow(name.to_s).cyan.bold
            puts "   #{description}" if config[CONFIG_KEYS[:description]]

            if config[CONFIG_KEYS[:start_command]]
              puts ""
              puts "   #{Rainbow('To start:').yellow}"
              puts "   #{Rainbow(config[CONFIG_KEYS[:start_command]]).green}"
            end

            if config[CONFIG_KEYS[:install_hint]]
              puts ""
              puts "   #{Rainbow('Not installed?').yellow} #{config[CONFIG_KEYS[:install_hint]]}"
            end

            puts ""
          end

          puts Rainbow("💡 Tips:").blue.bold
          puts "   • Start services manually, then run bin/dev again"
          puts "   • Or remove service from .dev-services.yml if not needed"
          puts "   • Or add service to Procfile.dev to start automatically"
          puts ""
        end
        # rubocop:enable Metrics/AbcSize
      end
    end
  end
end

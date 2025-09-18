# frozen_string_literal: true

require "json"
require_relative "utils"
require_relative "system_checker"

begin
  require "rainbow"
rescue LoadError
  # Fallback if Rainbow is not available - define Kernel-level Rainbow method
  # rubocop:disable Naming/MethodName
  def Rainbow(text)
    SimpleColorWrapper.new(text)
  end
  # rubocop:enable Naming/MethodName

  class SimpleColorWrapper
    def initialize(text)
      @text = text
    end

    def method_missing(_method, *_args)
      self
    end

    def respond_to_missing?(_method, _include_private = false)
      true
    end

    def to_s
      @text
    end
  end
end

module ReactOnRails
  # rubocop:disable Metrics/ClassLength, Metrics/AbcSize
  class Doctor
    MESSAGE_COLORS = {
      error: :red,
      warning: :yellow,
      success: :green,
      info: :blue
    }.freeze

    def initialize(verbose: false, fix: false)
      @verbose = verbose
      @fix = fix
      @checker = SystemChecker.new
    end

    def run_diagnosis
      print_header
      run_all_checks
      print_summary
      print_recommendations if should_show_recommendations?

      exit_with_status
    end

    private

    attr_reader :verbose, :fix, :checker

    def print_header
      puts Rainbow("\n#{'=' * 80}").cyan
      puts Rainbow("🩺 REACT ON RAILS DOCTOR").cyan.bold
      puts Rainbow("Diagnosing your React on Rails setup...").cyan
      puts Rainbow("=" * 80).cyan
      puts
    end

    def run_all_checks
      checks = [
        ["Environment Prerequisites", :check_environment],
        ["React on Rails Versions", :check_react_on_rails_versions],
        ["React on Rails Packages", :check_packages],
        ["Dependencies", :check_dependencies],
        ["Key Configuration Files", :check_key_files],
        ["Configuration Analysis", :check_configuration_details],
        ["bin/dev Launcher Setup", :check_bin_dev_launcher],
        ["Rails Integration", :check_rails],
        ["Webpack Configuration", :check_webpack],
        ["Testing Setup", :check_testing_setup],
        ["Development Environment", :check_development]
      ]

      checks.each do |section_name, check_method|
        initial_message_count = checker.messages.length
        send(check_method)

        # Only print header if messages were added
        if checker.messages.length > initial_message_count
          print_section_header(section_name)
          print_recent_messages(initial_message_count)
          puts
        end
      end
    end

    def print_section_header(section_name)
      puts Rainbow("#{section_name}:").blue.bold
      puts Rainbow("-" * (section_name.length + 1)).blue
    end

    def print_recent_messages(start_index)
      checker.messages[start_index..-1].each do |message|
        color = MESSAGE_COLORS[message[:type]] || :blue
        puts Rainbow(message[:content]).send(color)
      end
    end

    def check_environment
      checker.check_node_installation
      checker.check_package_manager
    end

    def check_react_on_rails_versions
      check_gem_version
      check_npm_package_version
      check_version_wildcards
    end

    def check_packages
      checker.check_react_on_rails_packages
      checker.check_shakapacker_configuration
    end

    def check_dependencies
      checker.check_react_dependencies
    end

    def check_rails
      checker.check_react_on_rails_initializer
    end

    def check_webpack
      checker.check_webpack_configuration
    end

    def check_key_files
      check_key_configuration_files
    end

    def check_configuration_details
      check_shakapacker_configuration_details
      check_react_on_rails_configuration_details
    end

    def check_bin_dev_launcher
      checker.add_info("🚀 bin/dev Launcher:")
      check_bin_dev_launcher_setup

      checker.add_info("\n📄 Launcher Procfiles:")
      check_launcher_procfiles
    end

    def check_testing_setup
      check_rspec_helper_setup
    end

    def check_development
      check_javascript_bundles
      check_procfile_dev
      check_bin_dev_script
      check_gitignore
    end

    def check_javascript_bundles
      server_bundle_path = determine_server_bundle_path
      if File.exist?(server_bundle_path)
        checker.add_success("✅ Server bundle file exists at #{server_bundle_path}")
      else
        checker.add_warning(<<~MSG.strip)
          ⚠️  Server bundle not found: #{server_bundle_path}

          This is required for server-side rendering.
          Check your Shakapacker configuration and ensure the bundle is compiled.
        MSG
      end
    end

    def check_procfile_dev
      check_procfiles
    end

    def check_procfiles
      procfiles = {
        "Procfile.dev" => {
          description: "HMR development with webpack-dev-server",
          required_for: "bin/dev (default/hmr mode)",
          should_contain: ["shakapacker-dev-server", "rails server"]
        },
        "Procfile.dev-static-assets" => {
          description: "Static development with webpack --watch",
          required_for: "bin/dev static",
          should_contain: ["shakapacker", "rails server"]
        },
        "Procfile.dev-prod-assets" => {
          description: "Production-optimized assets development",
          required_for: "bin/dev prod",
          should_contain: ["rails server"]
        }
      }

      procfiles.each do |filename, config|
        check_individual_procfile(filename, config)
      end

      # Check if at least Procfile.dev exists
      if File.exist?("Procfile.dev")
        checker.add_success("✅ Essential Procfiles available for bin/dev script")
      else
        checker.add_warning(<<~MSG.strip)
          ⚠️  Procfile.dev missing - required for bin/dev development server
          Run 'rails generate react_on_rails:install' to generate required Procfiles
        MSG
      end
    end

    def check_individual_procfile(filename, config)
      if File.exist?(filename)
        checker.add_success("✅ #{filename} exists (#{config[:description]})")

        # Only check for critical missing components, not optional suggestions
        content = File.read(filename)
        if filename == "Procfile.dev" && !content.include?("shakapacker-dev-server")
          checker.add_warning("  ⚠️  Missing shakapacker-dev-server for HMR development")
        elsif filename == "Procfile.dev-static-assets" && !content.include?("shakapacker")
          checker.add_warning("  ⚠️  Missing shakapacker for static asset compilation")
        end
      else
        checker.add_info("ℹ️  #{filename} not found (needed for #{config[:required_for]})")
      end
    end

    def check_bin_dev_script
      bin_dev_path = "bin/dev"
      if File.exist?(bin_dev_path)
        checker.add_success("✅ bin/dev script exists")
        check_bin_dev_content(bin_dev_path)
      else
        checker.add_warning(<<~MSG.strip)
          ⚠️  bin/dev script missing
          This script provides an enhanced development workflow with HMR, static, and production modes.
          Run 'rails generate react_on_rails:install' to generate the script.
        MSG
      end
    end

    def check_bin_dev_content(bin_dev_path)
      return unless File.exist?(bin_dev_path)

      content = File.read(bin_dev_path)

      # Check if it's using the new ReactOnRails::Dev::ServerManager
      if content.include?("ReactOnRails::Dev::ServerManager")
        checker.add_success("  ✓ Uses enhanced ReactOnRails development server")
      elsif content.include?("foreman") || content.include?("overmind")
        checker.add_info("  ℹ️  Using basic foreman/overmind - consider upgrading to ReactOnRails enhanced dev script")
      else
        checker.add_info("  ℹ️  Custom bin/dev script detected")
      end

      # Check if it's executable
      if File.executable?(bin_dev_path)
        checker.add_success("  ✓ Script is executable")
      else
        checker.add_warning("  ⚠️  Script is not executable - run 'chmod +x bin/dev'")
      end
    end

    def check_gitignore
      gitignore_path = ".gitignore"
      return unless File.exist?(gitignore_path)

      content = File.read(gitignore_path)
      if content.include?("**/generated/**")
        checker.add_success("✅ .gitignore excludes generated files")
      else
        checker.add_info("ℹ️  Consider adding '**/generated/**' to .gitignore")
      end
    end

    def print_summary
      print_summary_header
      counts = calculate_message_counts
      print_summary_message(counts)
      print_detailed_results_if_needed(counts)
    end

    def print_summary_header
      puts Rainbow("DIAGNOSIS COMPLETE").cyan.bold
      puts Rainbow("=" * 80).cyan
      puts
    end

    def calculate_message_counts
      {
        error: checker.messages.count { |msg| msg[:type] == :error },
        warning: checker.messages.count { |msg| msg[:type] == :warning },
        success: checker.messages.count { |msg| msg[:type] == :success }
      }
    end

    def print_summary_message(counts)
      if counts[:error].zero? && counts[:warning].zero?
        puts Rainbow("🎉 Excellent! Your React on Rails setup looks perfect!").green.bold
      elsif counts[:error].zero?
        puts Rainbow("✅ Good! Your setup is functional with #{counts[:warning]} minor issue(s).").yellow
      else
        puts Rainbow("❌ Issues found: #{counts[:error]} error(s), #{counts[:warning]} warning(s)").red
      end

      summary_text = "📊 Summary: #{counts[:success]} checks passed, " \
                     "#{counts[:warning]} warnings, #{counts[:error]} errors"
      puts Rainbow(summary_text).blue
    end

    def print_detailed_results_if_needed(counts)
      # Skip detailed results since messages are now printed under section headers
      # Only show detailed results in verbose mode for debugging
      return unless verbose

      puts "\nDetailed Results (Verbose Mode):"
      print_all_messages
    end

    def print_all_messages
      checker.messages.each do |message|
        color = MESSAGE_COLORS[message[:type]] || :blue

        puts Rainbow(message[:content]).send(color)
        puts
      end
    end

    def print_recommendations
      puts Rainbow("RECOMMENDATIONS").cyan.bold
      puts Rainbow("=" * 80).cyan

      if checker.errors?
        puts Rainbow("Critical Issues:").red.bold
        puts "• Fix the errors above before proceeding"
        puts "• Run 'rails generate react_on_rails:install' to set up missing components"
        puts "• Ensure all prerequisites (Node.js, package manager) are installed"
        puts
      end

      if checker.warnings?
        puts Rainbow("Suggested Improvements:").yellow.bold
        puts "• Review warnings above for optimization opportunities"

        # Enhanced development workflow recommendations
        unless File.exist?("bin/dev") && File.read("bin/dev").include?("ReactOnRails::Dev::ServerManager")
          puts "• #{Rainbow('Upgrade to enhanced bin/dev script').yellow}:"
          puts "  - Run #{Rainbow('rails generate react_on_rails:install').cyan} for latest development tools"
          puts "  - Provides HMR, static, and production-like asset modes"
          puts "  - Better error handling and debugging capabilities"
        end

        missing_procfiles = ["Procfile.dev-static-assets", "Procfile.dev-prod-assets"].reject { |f| File.exist?(f) }
        unless missing_procfiles.empty?
          puts "• #{Rainbow('Complete development workflow setup').yellow}:"
          puts "  - Missing: #{missing_procfiles.join(', ')}"
          puts "  - Run #{Rainbow('rails generate react_on_rails:install').cyan} to generate missing files"
        end

        puts "• Consider updating packages to latest compatible versions"
        puts "• Check documentation for best practices"
        puts
      end

      print_next_steps
    end

    def should_show_recommendations?
      # Only show recommendations if there are actual issues or actionable improvements
      checker.errors? || checker.warnings?
    end

    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def print_next_steps
      puts Rainbow("Next Steps:").blue.bold

      if checker.errors?
        puts "• Fix critical errors above before proceeding"
        puts "• Run doctor again to verify fixes: rake react_on_rails:doctor"
      elsif checker.warnings?
        puts "• Address warnings above for optimal setup"
        puts "• Run doctor again to verify improvements: rake react_on_rails:doctor"
      else
        puts "• Your setup is healthy! Consider these development workflow steps:"
      end

      # Enhanced contextual suggestions based on what exists
      if File.exist?("bin/dev") && File.exist?("Procfile.dev")
        puts "• Start development with HMR: #{Rainbow('./bin/dev').cyan}"
        puts "• Try static mode: #{Rainbow('./bin/dev static').cyan}"
        puts "• Test production assets: #{Rainbow('./bin/dev prod').cyan}"
        puts "• See all options: #{Rainbow('./bin/dev help').cyan}"
      elsif File.exist?("Procfile.dev")
        puts "• Start development with: #{Rainbow('./bin/dev').cyan} (or foreman start -f Procfile.dev)"
      else
        puts "• Start Rails server: bin/rails server"
        puts "• Start webpack dev server: bin/shakapacker-dev-server (in separate terminal)"
      end

      # Test suggestions based on what's available
      test_suggestions = []
      test_suggestions << "bundle exec rspec" if File.exist?("spec")
      test_suggestions << "npm test" if npm_test_script?
      test_suggestions << "yarn test" if yarn_test_script?

      puts "• Run tests: #{test_suggestions.join(' or ')}" if test_suggestions.any?

      # Build suggestions
      if checker.messages.any? { |msg| msg[:content].include?("server bundle") }
        puts "• Build assets: bin/shakapacker or npm run build"
      end

      puts "• Documentation: https://github.com/shakacode/react_on_rails"
      puts
    end
    # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

    def check_gem_version
      gem_version = ReactOnRails::VERSION
      checker.add_success("✅ React on Rails gem version: #{gem_version}")
    rescue StandardError
      checker.add_error("🚫 Unable to determine React on Rails gem version")
    end

    def check_npm_package_version
      return unless File.exist?("package.json")

      begin
        package_json = JSON.parse(File.read("package.json"))
        all_deps = package_json["dependencies"]&.merge(package_json["devDependencies"] || {}) || {}

        npm_version = all_deps["react-on-rails"]
        if npm_version
          checker.add_success("✅ react-on-rails npm package version: #{npm_version}")
        else
          checker.add_warning("⚠️  react-on-rails npm package not found in package.json")
        end
      rescue JSON::ParserError
        checker.add_error("🚫 Unable to parse package.json")
      rescue StandardError
        checker.add_error("🚫 Error reading package.json")
      end
    end

    def check_version_wildcards
      check_gem_wildcards
      check_npm_wildcards
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    def check_gem_wildcards
      gemfile_path = ENV["BUNDLE_GEMFILE"] || "Gemfile"
      return unless File.exist?(gemfile_path)

      begin
        content = File.read(gemfile_path)
        react_line = content.lines.find { |line| line.match(/^\s*gem\s+['"]react_on_rails['"]/) }

        if react_line
          if /['"][~^]/.match?(react_line)
            checker.add_warning("⚠️  Gemfile uses wildcard version pattern (~, ^) for react_on_rails")
          elsif />=\s*/.match?(react_line)
            checker.add_warning("⚠️  Gemfile uses version range (>=) for react_on_rails")
          else
            checker.add_success("✅ Gemfile uses exact version for react_on_rails")
          end
        end
      rescue StandardError
        # Ignore errors reading Gemfile
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    # rubocop:disable Metrics/CyclomaticComplexity
    def check_npm_wildcards
      return unless File.exist?("package.json")

      begin
        package_json = JSON.parse(File.read("package.json"))
        all_deps = package_json["dependencies"]&.merge(package_json["devDependencies"] || {}) || {}

        npm_version = all_deps["react-on-rails"]
        if npm_version
          if /[~^]/.match?(npm_version)
            checker.add_warning("⚠️  package.json uses wildcard version pattern (~, ^) for react-on-rails")
          else
            checker.add_success("✅ package.json uses exact version for react-on-rails")
          end
        end
      rescue JSON::ParserError
        # Ignore JSON parsing errors
      rescue StandardError
        # Ignore other errors
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    def check_key_configuration_files
      files_to_check = {
        "config/shakapacker.yml" => "Shakapacker configuration",
        "config/initializers/react_on_rails.rb" => "React on Rails initializer",
        "bin/shakapacker" => "Shakapacker binary",
        "bin/shakapacker-dev-server" => "Shakapacker dev server binary",
        "config/webpack/webpack.config.js" => "Webpack configuration"
      }

      files_to_check.each do |file_path, description|
        if File.exist?(file_path)
          checker.add_success("✅ #{description}: #{file_path}")
        else
          checker.add_warning("⚠️  Missing #{description}: #{file_path}")
        end
      end
    end

    def check_shakapacker_configuration_details
      return unless File.exist?("config/shakapacker.yml")

      # For now, just indicate that the configuration file exists
      # TODO: Parse YAML directly or improve Shakapacker integration
      checker.add_info("📋 Shakapacker Configuration:")
      checker.add_info("  Configuration file: config/shakapacker.yml")
      checker.add_info("  ℹ️  Run 'rake shakapacker:info' for detailed configuration")
    end

    def check_react_on_rails_configuration_details
      config_path = "config/initializers/react_on_rails.rb"
      return unless File.exist?(config_path)

      begin
        content = File.read(config_path)

        checker.add_info("📋 React on Rails Configuration:")

        # Extract key configuration values
        config_patterns = {
          "server_bundle_js_file" => /config\.server_bundle_js_file\s*=\s*["']([^"']+)["']/,
          "prerender" => /config\.prerender\s*=\s*([^\s\n]+)/,
          "trace" => /config\.trace\s*=\s*([^\s\n]+)/,
          "development_mode" => /config\.development_mode\s*=\s*([^\s\n]+)/,
          "logging_on_server" => /config\.logging_on_server\s*=\s*([^\s\n]+)/
        }

        config_patterns.each do |setting, pattern|
          match = content.match(pattern)
          checker.add_info("  #{setting}: #{match[1]}") if match
        end
      rescue StandardError => e
        checker.add_warning("⚠️  Unable to read react_on_rails.rb: #{e.message}")
      end
    end

    def check_bin_dev_launcher_setup
      bin_dev_path = "bin/dev"

      unless File.exist?(bin_dev_path)
        checker.add_error("  🚫 bin/dev script not found")
        return
      end

      content = File.read(bin_dev_path)

      if content.include?("ReactOnRails::Dev::ServerManager")
        checker.add_success("  ✅ bin/dev uses ReactOnRails Launcher (ReactOnRails::Dev::ServerManager)")
      elsif content.include?("run_from_command_line")
        checker.add_success("  ✅ bin/dev uses ReactOnRails Launcher (run_from_command_line)")
      else
        checker.add_warning("  ⚠️  bin/dev exists but doesn't use ReactOnRails Launcher")
        checker.add_info("    💡 Consider upgrading: rails generate react_on_rails:install")
      end
    end

    def check_launcher_procfiles
      procfiles = {
        "Procfile.dev" => "HMR development (bin/dev default)",
        "Procfile.dev-static-assets" => "Static development (bin/dev static)",
        "Procfile.dev-prod-assets" => "Production assets (bin/dev prod)"
      }

      missing_count = 0

      procfiles.each do |filename, description|
        if File.exist?(filename)
          checker.add_success("  ✅ #{filename} - #{description}")
        else
          checker.add_warning("  ⚠️  Missing #{filename} - #{description}")
          missing_count += 1
        end
      end

      if missing_count.zero?
        checker.add_success("  ✅ All Launcher Procfiles available")
      else
        checker.add_info("  💡 Run: rails generate react_on_rails:install")
      end
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    def check_rspec_helper_setup
      spec_helper_paths = [
        "spec/rails_helper.rb",
        "spec/spec_helper.rb"
      ]

      react_on_rails_test_helper_found = false

      spec_helper_paths.each do |helper_path|
        next unless File.exist?(helper_path)

        content = File.read(helper_path)

        unless content.include?("ReactOnRails::TestHelper") || content.include?("configure_rspec_to_compile_assets")
          next
        end

        checker.add_success("✅ ReactOnRails RSpec helper configured in #{helper_path}")
        react_on_rails_test_helper_found = true

        # Check specific configurations
        checker.add_success("  ✓ Assets compilation enabled for tests") if content.include?("ensure_assets_compiled")

        checker.add_success("  ✓ RSpec configuration present") if content.include?("RSpec.configure")
      end

      return if react_on_rails_test_helper_found

      if File.exist?("spec")
        checker.add_warning("⚠️  ReactOnRails RSpec helper not found")
        checker.add_info("  Add to spec/rails_helper.rb:")
        checker.add_info("  require 'react_on_rails/test_helper'")
        checker.add_info("  ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)")
      else
        checker.add_info("ℹ️  No RSpec directory found - skipping RSpec helper check")
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    def npm_test_script?
      return false unless File.exist?("package.json")

      begin
        package_json = JSON.parse(File.read("package.json"))
        test_script = package_json.dig("scripts", "test")
        test_script && !test_script.empty?
      rescue StandardError
        false
      end
    end

    def yarn_test_script?
      npm_test_script? && system("which yarn > /dev/null 2>&1")
    end

    def determine_server_bundle_path
      # Try to use Shakapacker gem API to get configuration

      require "shakapacker"

      # Get the source path relative to Rails root
      source_path = Shakapacker.config.source_path.to_s
      source_entry_path = Shakapacker.config.source_entry_path.to_s
      bundle_filename = server_bundle_filename
      rails_root = Dir.pwd

      # Convert absolute paths to relative paths
      if source_path.start_with?("/") && source_path.start_with?(rails_root)
        source_path = source_path.sub("#{rails_root}/", "")
      end

      if source_entry_path.start_with?("/") && source_entry_path.start_with?(rails_root)
        source_entry_path = source_entry_path.sub("#{rails_root}/", "")
      end

      # If source_entry_path is already within source_path, just use the relative part
      if source_entry_path.start_with?(source_path)
        # Extract just the entry path part (e.g., "packs" from "client/app/packs")
        source_entry_path = source_entry_path.sub("#{source_path}/", "")
      end

      File.join(source_path, source_entry_path, bundle_filename)
    rescue StandardError
      # Handle missing Shakapacker gem or other configuration errors
      bundle_filename = server_bundle_filename
      "app/javascript/packs/#{bundle_filename}"
    end

    def server_bundle_filename
      # Try to read from React on Rails initializer
      initializer_path = "config/initializers/react_on_rails.rb"
      if File.exist?(initializer_path)
        content = File.read(initializer_path)
        match = content.match(/config\.server_bundle_js_file\s*=\s*["']([^"']+)["']/)
        return match[1] if match
      end

      # Default filename
      "server-bundle.js"
    end

    def exit_with_status
      if checker.errors?
        puts Rainbow("❌ Doctor found critical issues. Please address errors above.").red.bold
        exit(1)
      elsif checker.warnings?
        puts Rainbow("⚠️  Doctor found some issues. Consider addressing warnings above.").yellow
        exit(0)
      else
        puts Rainbow("🎉 All checks passed! Your React on Rails setup is healthy.").green.bold
        exit(0)
      end
    end

    def relativize_path(absolute_path)
      return absolute_path unless absolute_path.is_a?(String)

      project_root = Dir.pwd
      if absolute_path.start_with?(project_root)
        # Remove project root and leading slash to make it relative
        relative = absolute_path.sub(project_root, "").sub(/^\//, "")
        relative.empty? ? "." : relative
      else
        absolute_path
      end
    end

    def safe_display_config_path(label, path_value)
      return unless path_value

      begin
        # Convert to string and relativize
        path_str = path_value.to_s
        relative_path = relativize_path(path_str)
        checker.add_info("  #{label}: #{relative_path}")
      rescue StandardError => e
        checker.add_info("  #{label}: <error reading path: #{e.message}>")
      end
    end

    def safe_display_config_value(label, config, method_name)
      return unless config.respond_to?(method_name)

      begin
        value = config.send(method_name)
        checker.add_info("  #{label}: #{value}")
      rescue StandardError => e
        checker.add_info("  #{label}: <error reading value: #{e.message}>")
      end
    end
  end
  # rubocop:enable Metrics/ClassLength, Metrics/AbcSize
end

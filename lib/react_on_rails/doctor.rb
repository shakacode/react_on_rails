# frozen_string_literal: true

require "json"
require_relative "utils"
require_relative "system_checker"

begin
  require "rainbow"
rescue LoadError
  # Fallback if Rainbow is not available - define Kernel-level Rainbow method
  def Rainbow(text)
    SimpleColorWrapper.new(text)
  end

  class SimpleColorWrapper
    def initialize(text)
      @text = text
    end

    def method_missing(method, *args)
      self
    end

    def respond_to_missing?(method, include_private = false)
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
        ["React on Rails Packages", :check_packages],
        ["Dependencies", :check_dependencies],
        ["Rails Integration", :check_rails],
        ["Webpack Configuration", :check_webpack],
        ["Development Environment", :check_development]
      ]

      checks.each do |section_name, check_method|
        print_section_header(section_name)
        send(check_method)
        puts
      end
    end

    def print_section_header(section_name)
      puts Rainbow("#{section_name}:").blue.bold
      puts Rainbow("-" * (section_name.length + 1)).blue
    end

    def check_environment
      checker.check_node_installation
      checker.check_package_manager
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

        content = File.read(filename)
        config[:should_contain].each do |expected_content|
          if content.include?(expected_content)
            checker.add_success("  ✓ Contains #{expected_content}")
          else
            checker.add_info("  ℹ️  Could include #{expected_content} for #{config[:description]}")
          end
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
      return unless verbose || counts[:error].positive? || counts[:warning].positive?

      puts "\nDetailed Results:"
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
      server_bundle_filename = server_bundle_filename
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

      File.join(source_path, source_entry_path, server_bundle_filename)
    rescue LoadError, NameError, StandardError
      # Fallback to default paths if Shakapacker is not available or configured
      server_bundle_filename = get_server_bundle_filename
      "app/javascript/packs/#{server_bundle_filename}"
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
  end
  # rubocop:enable Metrics/ClassLength, Metrics/AbcSize
end

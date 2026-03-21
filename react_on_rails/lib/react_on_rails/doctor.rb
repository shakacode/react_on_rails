# frozen_string_literal: true

require "json"
require "erb"
require "yaml"
require_relative "utils"
require_relative "config_path_resolver"
require_relative "version_syntax_converter"
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
    include ConfigPathResolver

    MESSAGE_COLORS = {
      error: :red,
      warning: :yellow,
      success: :green,
      info: :blue
    }.freeze

    RSPEC_HELPER_FILES = ["spec/rails_helper.rb", "spec/spec_helper.rb"].freeze
    MINITEST_HELPER_FILE = "test/test_helper.rb"
    DEFAULT_BUILD_TEST_COMMAND = 'config.build_test_command = "RAILS_ENV=test bin/shakapacker"'
    DEFAULT_SHAKAPACKER_CONFIG_PATH = "config/shakapacker.yml"

    def initialize(verbose: false, fix: false)
      @verbose = verbose
      @fix = fix
      @checker = SystemChecker.new
      @test_output_path_strategy = :unknown
      @rails_environment_loaded = false
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
      print_doctor_feature_info
      puts
    end

    def print_doctor_feature_info
      puts Rainbow("ℹ️  Doctor Feature Information:").blue
      puts "   • This diagnostic tool is available in React on Rails v16.0.0+"
      puts "   • For older versions, upgrade your gem to access this feature"
      puts "   • Run: bundle update react_on_rails"
      puts "   • Documentation: https://reactonrails.com/docs/"
    end

    def run_all_checks
      checks = [
        ["Environment Prerequisites", :check_environment],
        ["React on Rails Versions", :check_react_on_rails_versions],
        ["React on Rails Packages", :check_packages],
        ["JavaScript Package Dependencies", :check_dependencies],
        ["Key Configuration Files", :check_key_files],
        ["Configuration Analysis", :check_configuration_details],
        ["bin/dev Launcher Setup", :check_bin_dev_launcher],
        ["Rails Integration", :check_rails],
        ["Webpack Configuration", :check_webpack],
        ["Testing Setup", :check_testing_setup],
        ["Development Environment", :check_development],
        ["React on Rails Pro Setup", :check_pro_setup],
        ["React Server Components", :check_rsc_setup]
      ]

      checks.each do |section_name, check_method|
        initial_message_count = checker.messages.length
        send(check_method)

        # Only print header if messages were added
        next unless checker.messages.length > initial_message_count

        print_section_header(section_name)
        print_recent_messages(initial_message_count)
        puts
      end
    end

    def print_section_header(section_name)
      puts Rainbow("#{section_name}:").blue.bold
      puts Rainbow("-" * (section_name.length + 1)).blue
    end

    def print_recent_messages(start_index)
      checker.messages[start_index..].each do |message|
        color = MESSAGE_COLORS[message[:type]] || :blue
        puts Rainbow(message[:content]).send(color)
      end
    end

    def check_environment
      checker.check_node_installation
      checker.check_package_manager
    end

    def check_react_on_rails_versions
      # Use system_checker for comprehensive package validation instead of duplicating
      checker.check_react_on_rails_packages
      check_version_wildcards
      check_pro_package_consistency
    end

    def check_packages
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
      check_server_bundle_prerender_consistency
    end

    def check_bin_dev_launcher
      checker.add_info("🚀 bin/dev Launcher:")
      check_bin_dev_launcher_setup

      checker.add_info("\n📄 Launcher Procfiles:")
      check_launcher_procfiles
    end

    def check_testing_setup
      check_test_helper_setup
      check_build_test_configuration
      check_shared_output_paths_with_hmr
      check_minitest_system_test_wiring
      check_capybara_external_server_mode
    end

    def check_development
      check_javascript_bundles
      check_procfile_dev
      check_bin_dev_script
      check_gitignore
      check_async_usage
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

    def print_detailed_results_if_needed(_counts)
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

      puts "• Auto-apply supported fixes: FIX=true rake react_on_rails:doctor"

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
      print_test_workflow_next_steps

      # Build suggestions
      if checker.messages.any? { |msg| msg[:content].include?("server bundle") }
        puts "• Build assets: bin/shakapacker or npm run build"
      end

      puts "• Documentation: https://github.com/shakacode/react_on_rails"
      puts
    end
    # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

    def print_test_workflow_next_steps
      case @test_output_path_strategy
      when :shared
        puts "• Shared test/dev output path detected: use static workflow only"
        puts "  - Start app with: ./bin/dev static"
        puts "  - Avoid ./bin/dev (HMR) with shared output paths"
        puts "  - Start test watcher with: ./bin/dev test-watch --test-watch-mode=client-only"
      when :separate
        puts "• Recommended default: keep test output path separate from development"
        puts "• Start test watcher with: ./bin/dev test-watch (auto mode)"
      end
    end

    def check_gem_version
      gem_version = ReactOnRails::VERSION
      checker.add_success("✅ React on Rails gem version: #{gem_version}")
    rescue StandardError
      checker.add_error("🚫 Unable to determine React on Rails gem version")
    end

    def check_npm_package_version
      package_json_path = resolved_package_json_path
      return unless File.exist?(package_json_path)

      begin
        package_json = JSON.parse(File.read(package_json_path))
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

    def check_npm_wildcards
      package_json_path = resolved_package_json_path
      return unless File.exist?(package_json_path)

      begin
        package_json = JSON.parse(File.read(package_json_path))
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

    def check_pro_package_consistency
      package_json_path = resolved_package_json_path
      return unless File.exist?(package_json_path)

      package_json = JSON.parse(File.read(package_json_path))
      all_deps = (package_json["dependencies"] || {}).merge(package_json["devDependencies"] || {})
      has_base = all_deps.key?("react-on-rails")
      has_pro = all_deps.key?("react-on-rails-pro")
      is_pro_gem = ReactOnRails::Utils.react_on_rails_pro?

      check_duplicate_packages(has_base, has_pro)
      check_pro_gem_package_mismatch(is_pro_gem, has_base, has_pro)
      check_pro_package_without_gem(is_pro_gem, has_pro)
    rescue StandardError => e
      checker.add_warning("⚠️  Pro package consistency check failed: #{e.message}")
    end

    def check_duplicate_packages(has_base, has_pro)
      return unless has_base && has_pro

      remove_cmd = ReactOnRails::Utils.package_manager_remove_command("react-on-rails")
      checker.add_error(<<~MSG.strip)
        🚫 Both 'react-on-rails' and 'react-on-rails-pro' npm packages are installed.

        The Pro package includes all base functionality. Having both causes conflicts.

        Fix: #{remove_cmd}
      MSG
    end

    def check_pro_gem_package_mismatch(is_pro_gem, has_base, has_pro)
      return unless is_pro_gem && has_base && !has_pro

      pro_gem_version = ReactOnRails::Utils.react_on_rails_pro_version
      gem_version = pro_gem_version.empty? ? ReactOnRails::VERSION : pro_gem_version
      npm_version = ReactOnRails::VersionSyntaxConverter.new.rubygem_to_npm(gem_version)
      install_cmd = ReactOnRails::Utils.package_manager_install_exact_command(
        "react-on-rails-pro", npm_version
      )
      checker.add_error(<<~MSG.strip)
        🚫 Pro gem is installed but using the base 'react-on-rails' npm package.

        The Pro gem requires the 'react-on-rails-pro' npm package.

        Fix: #{install_cmd}
      MSG
    end

    def check_pro_package_without_gem(is_pro_gem, has_pro)
      return if is_pro_gem || !has_pro

      checker.add_error(<<~MSG.strip)
        🚫 'react-on-rails-pro' npm package is installed but the Pro gem is not.

        The Pro npm package requires the 'react_on_rails_pro' gem.

        Fix: Add gem 'react_on_rails_pro' to your Gemfile and run bundle install
      MSG
    end

    def check_key_configuration_files
      files_to_check = {
        "config/shakapacker.yml" => "Shakapacker configuration",
        "config/initializers/react_on_rails.rb" => "React on Rails initializer",
        "bin/dev" => "Development server launcher",
        "bin/shakapacker" => "Shakapacker binary",
        "bin/shakapacker-dev-server" => "Shakapacker dev server binary"
      }

      files_to_check.each do |file_path, description|
        if File.exist?(file_path)
          checker.add_success("✅ #{description}: #{file_path}")
        else
          checker.add_warning("⚠️  Missing #{description}: #{file_path}")
        end
      end

      webpack_config_path = resolved_webpack_config_path
      if webpack_config_path
        checker.add_success("✅ Webpack configuration: #{webpack_config_path}")
      else
        checker.add_warning("⚠️  Missing Webpack configuration: config/webpack/webpack.config.js")
        checker.add_info(
          "ℹ️  If your app uses a custom webpack config location, this warning may be informational."
        )
      end

      check_layout_files
      check_server_rendering_engine
    end

    def check_layout_files
      layout_files = Dir.glob("app/views/layouts/**/*.erb")
      return if layout_files.empty?

      checker.add_info("\n📄 Layout Files Analysis:")

      layout_files.each do |layout_file|
        next unless File.exist?(layout_file)

        content = File.read(layout_file)
        has_stylesheet = content.include?("stylesheet_pack_tag")
        has_javascript = content.include?("javascript_pack_tag")

        layout_name = File.basename(layout_file, ".html.erb")

        if has_stylesheet && has_javascript
          checker.add_info("  ✅ #{layout_name}: has both stylesheet_pack_tag and javascript_pack_tag")
        elsif has_stylesheet
          checker.add_warning("  ⚠️  #{layout_name}: has stylesheet_pack_tag but missing javascript_pack_tag")
        elsif has_javascript
          checker.add_warning("  ⚠️  #{layout_name}: has javascript_pack_tag but missing stylesheet_pack_tag")
        else
          checker.add_info("  ℹ️  #{layout_name}: no pack tags found")
        end
      end
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    def check_server_rendering_engine
      return unless defined?(ReactOnRails)

      checker.add_info("\n🖥️  Server Rendering Engine:")

      begin
        # Check if ExecJS is available and what runtime is being used
        if defined?(ExecJS)
          runtime_name = ExecJS.runtime.name if ExecJS.runtime
          if runtime_name
            checker.add_info("  ExecJS Runtime: #{runtime_name}")

            # Provide more specific information about the runtime
            case runtime_name
            when /MiniRacer/
              checker.add_info("    ℹ️  Using V8 via mini_racer gem (fast, isolated)")
            when /Node/
              checker.add_info("    ℹ️  Using Node.js runtime (requires Node.js)")
            when /Duktape/
              checker.add_info("    ℹ️  Using Duktape runtime (pure Ruby, slower)")
            else
              checker.add_info("    ℹ️  JavaScript runtime: #{runtime_name}")
            end
          else
            checker.add_warning("  ⚠️  ExecJS runtime not detected")
          end
        else
          checker.add_warning("  ⚠️  ExecJS not available")
        end
      rescue StandardError => e
        checker.add_warning("  ⚠️  Could not determine server rendering engine: #{e.message}")
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    def check_shakapacker_configuration_details
      return unless File.exist?("config/shakapacker.yml")

      checker.add_info("📋 Shakapacker Configuration:")

      begin
        # Run shakapacker:info to get detailed configuration
        stdout, stderr, status = Open3.capture3("bundle", "exec", "rake", "shakapacker:info")

        if status.success?
          # Parse and display relevant info from shakapacker:info
          lines = stdout.lines.map(&:strip)

          lines.each do |line|
            next if line.empty?

            # Show only Shakapacker-specific configuration lines, not general environment info
            checker.add_info("  #{line}") if line.match?(%r{^Is bin/shakapacker})
          end
        else
          checker.add_info("  Configuration file: config/shakapacker.yml")
          checker.add_warning("  ⚠️  Could not run 'rake shakapacker:info': #{stderr.strip}")
        end
      rescue StandardError => e
        checker.add_info("  Configuration file: config/shakapacker.yml")
        checker.add_warning("  ⚠️  Could not run 'rake shakapacker:info': #{e.message}")
      end
    end

    def check_react_on_rails_configuration_details
      check_react_on_rails_initializer
      check_deprecated_configuration_settings
      check_breaking_changes_warnings
    end

    def check_react_on_rails_initializer
      config_path = "config/initializers/react_on_rails.rb"

      unless File.exist?(config_path)
        checker.add_warning("⚠️  React on Rails configuration file not found: #{config_path}")
        checker.add_info("💡 Run 'rails generate react_on_rails:install' to create configuration file")
        return
      end

      begin
        content = File.read(config_path)

        checker.add_info("📋 React on Rails Configuration:")
        checker.add_info("📍 Documentation: https://reactonrails.com/docs/guides/configuration/")

        # Analyze configuration settings
        analyze_server_rendering_config(content)
        analyze_performance_config(content)
        analyze_development_config(content)
        analyze_i18n_config(content)
        analyze_component_loading_config(content)
        analyze_custom_extensions(content)
      rescue StandardError => e
        checker.add_warning("⚠️  Unable to read react_on_rails.rb: #{e.message}")
      end
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    def analyze_server_rendering_config(content)
      checker.add_info("\n🖥️  Server Rendering:")

      # Server bundle file
      server_bundle_match = content.match(/config\.server_bundle_js_file\s*=\s*["']([^"']+)["']/)
      if server_bundle_match
        checker.add_info("  server_bundle_js_file: #{server_bundle_match[1]}")
      else
        checker.add_info("  server_bundle_js_file: server-bundle.js (default)")
      end

      # Server bundle output path
      server_bundle_path_match = content.match(/config\.server_bundle_output_path\s*=\s*["']([^"']+)["']/)
      default_path = ReactOnRails::DEFAULT_SERVER_BUNDLE_OUTPUT_PATH
      rails_bundle_path = server_bundle_path_match ? server_bundle_path_match[1] : default_path
      checker.add_info("  server_bundle_output_path: #{rails_bundle_path}")

      # Enforce private server bundles
      enforce_private_match = content.match(/config\.enforce_private_server_bundles\s*=\s*([^\s\n,]+)/)
      checker.add_info("  enforce_private_server_bundles: #{enforce_private_match[1]}") if enforce_private_match

      # Check Shakapacker integration and provide recommendations
      check_shakapacker_private_output_path(rails_bundle_path)

      # RSC bundle file (Pro feature)
      rsc_bundle_match = content.match(/config\.rsc_bundle_js_file\s*=\s*["']([^"']+)["']/)
      if rsc_bundle_match
        checker.add_info("  rsc_bundle_js_file: #{rsc_bundle_match[1]} (React Server Components - Pro)")
      end

      # Prerender setting
      prerender_match = content.match(/config\.prerender\s*=\s*([^\s\n,]+)/)
      prerender_value = prerender_match ? prerender_match[1] : "false (default)"
      checker.add_info("  prerender: #{prerender_value}")

      # Server renderer pool settings
      pool_size_match = content.match(/config\.server_renderer_pool_size\s*=\s*([^\s\n,]+)/)
      checker.add_info("  server_renderer_pool_size: #{pool_size_match[1]}") if pool_size_match

      timeout_match = content.match(/config\.server_renderer_timeout\s*=\s*([^\s\n,]+)/)
      checker.add_info("  server_renderer_timeout: #{timeout_match[1]} seconds") if timeout_match

      # Error handling
      raise_on_error_match = content.match(/config\.raise_on_prerender_error\s*=\s*([^\s\n,]+)/)
      return unless raise_on_error_match

      checker.add_info("  raise_on_prerender_error: #{raise_on_error_match[1]}")
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    # rubocop:disable Metrics/CyclomaticComplexity
    def analyze_performance_config(content)
      checker.add_info("\n⚡ Performance & Loading:")

      # Component loading strategy
      loading_strategy_match = content.match(/config\.generated_component_packs_loading_strategy\s*=\s*:([^\s\n,]+)/)
      if loading_strategy_match
        strategy = loading_strategy_match[1]
        checker.add_info("  generated_component_packs_loading_strategy: :#{strategy}")

        case strategy
        when "async"
          checker.add_info("    ℹ️  Async loading requires Shakapacker >= 8.2.0")
        when "defer"
          checker.add_info("    ℹ️  Deferred loading provides good performance balance")
        when "sync"
          checker.add_info("    ℹ️  Synchronous loading ensures immediate availability")
        end
      end

      # Deprecated defer setting
      defer_match = content.match(/config\.defer_generated_component_packs\s*=\s*([^\s\n,]+)/)
      if defer_match
        checker.add_warning("  ⚠️  defer_generated_component_packs: #{defer_match[1]} (DEPRECATED)")
        checker.add_info("    💡 Use generated_component_packs_loading_strategy = :defer instead")
      end

      # Auto load bundle
      auto_load_match = content.match(/config\.auto_load_bundle\s*=\s*([^\s\n,]+)/)
      checker.add_info("  auto_load_bundle: #{auto_load_match[1]}") if auto_load_match

      # Deprecated immediate_hydration setting
      immediate_hydration_match = content.match(/config\.immediate_hydration\s*=\s*([^\s\n,]+)/)
      if immediate_hydration_match
        checker.add_warning("  ⚠️  immediate_hydration: #{immediate_hydration_match[1]} (DEPRECATED)")
        checker.add_info("    💡 This setting is no longer used. Immediate hydration is now automatic for Pro users.")
        checker.add_info("    💡 Remove this line from your config/initializers/react_on_rails.rb file.")
      end

      # Component registry timeout
      timeout_match = content.match(/config\.component_registry_timeout\s*=\s*([^\s\n,]+)/)
      return unless timeout_match

      checker.add_info("  component_registry_timeout: #{timeout_match[1]}ms")
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity

    # rubocop:disable Metrics/AbcSize
    def analyze_development_config(content)
      checker.add_info("\n🔧 Development & Debugging:")

      # Development mode
      dev_mode_match = content.match(/config\.development_mode\s*=\s*([^\s\n,]+)/)
      if dev_mode_match
        checker.add_info("  development_mode: #{dev_mode_match[1]}")
      else
        checker.add_info("  development_mode: Rails.env.development? (default)")
      end

      # Trace setting
      trace_match = content.match(/config\.trace\s*=\s*([^\s\n,]+)/)
      if trace_match
        checker.add_info("  trace: #{trace_match[1]}")
      else
        checker.add_info("  trace: Rails.env.development? (default)")
      end

      # Logging
      logging_match = content.match(/config\.logging_on_server\s*=\s*([^\s\n,]+)/)
      logging_value = logging_match ? logging_match[1] : "true (default)"
      checker.add_info("  logging_on_server: #{logging_value}")

      # Console replay
      replay_match = content.match(/config\.replay_console\s*=\s*([^\s\n,]+)/)
      replay_value = replay_match ? replay_match[1] : "true (default)"
      checker.add_info("  replay_console: #{replay_value}")

      # Build commands
      build_test_match = content.match(/config\.build_test_command\s*=\s*["']([^"']+)["']/)
      checker.add_info("  build_test_command: #{build_test_match[1]}") if build_test_match

      build_prod_match = content.match(/config\.build_production_command\s*=\s*["']([^"']+)["']/)
      return unless build_prod_match

      checker.add_info("  build_production_command: #{build_prod_match[1]}")
    end
    # rubocop:enable Metrics/AbcSize

    def analyze_i18n_config(content)
      i18n_configs = []

      i18n_dir_match = content.match(/config\.i18n_dir\s*=\s*["']([^"']+)["']/)
      i18n_configs << "i18n_dir: #{i18n_dir_match[1]}" if i18n_dir_match

      i18n_yml_dir_match = content.match(/config\.i18n_yml_dir\s*=\s*["']([^"']+)["']/)
      i18n_configs << "i18n_yml_dir: #{i18n_yml_dir_match[1]}" if i18n_yml_dir_match

      i18n_format_match = content.match(/config\.i18n_output_format\s*=\s*["']([^"']+)["']/)
      i18n_configs << "i18n_output_format: #{i18n_format_match[1]}" if i18n_format_match

      return unless i18n_configs.any?

      checker.add_info("\n🌍 Internationalization:")
      i18n_configs.each { |config| checker.add_info("  #{config}") }
    end

    def analyze_component_loading_config(content)
      component_configs = []

      components_subdir_match = content.match(/config\.components_subdirectory\s*=\s*["']([^"']+)["']/)
      if components_subdir_match
        component_configs << "components_subdirectory: #{components_subdir_match[1]}"
        checker.add_info("    ℹ️  File-system based component registry enabled")
      end

      same_bundle_match = content.match(/config\.same_bundle_for_client_and_server\s*=\s*([^\s\n,]+)/)
      component_configs << "same_bundle_for_client_and_server: #{same_bundle_match[1]}" if same_bundle_match

      random_dom_match = content.match(/config\.random_dom_id\s*=\s*([^\s\n,]+)/)
      component_configs << "random_dom_id: #{random_dom_match[1]}" if random_dom_match

      return unless component_configs.any?

      checker.add_info("\n📦 Component Loading:")
      component_configs.each { |config| checker.add_info("  #{config}") }
    end

    def analyze_custom_extensions(content)
      # Check for rendering extension
      if /config\.rendering_extension\s*=\s*([^\s\n,]+)/.match?(content)
        checker.add_info("\n🔌 Custom Extensions:")
        checker.add_info("  rendering_extension: Custom rendering logic detected")
        checker.add_info("    ℹ️  See: https://reactonrails.com/docs/guides/rendering-extensions")
      end

      # Check for rendering props extension
      if /config\.rendering_props_extension\s*=\s*([^\s\n,]+)/.match?(content)
        checker.add_info("  rendering_props_extension: Custom props logic detected")
      end

      # Check for server render method
      server_method_match = content.match(/config\.server_render_method\s*=\s*["']([^"']+)["']/)
      return unless server_method_match

      checker.add_info("  server_render_method: #{server_method_match[1]}")
    end

    def check_deprecated_configuration_settings
      return unless File.exist?("config/initializers/react_on_rails.rb")

      content = File.read("config/initializers/react_on_rails.rb")
      deprecated_settings = []

      # Check for deprecated settings
      if content.include?("config.generated_assets_dirs")
        deprecated_settings << "generated_assets_dirs (use generated_assets_dir)"
      end
      if content.include?("config.skip_display_none")
        deprecated_settings << "skip_display_none (remove from configuration)"
      end
      if content.include?("config.defer_generated_component_packs")
        deprecated_settings << "defer_generated_component_packs (use generated_component_packs_loading_strategy)"
      end

      return unless deprecated_settings.any?

      checker.add_info("\n⚠️  Deprecated Configuration Settings:")
      deprecated_settings.each do |setting|
        checker.add_warning("  #{setting}")
      end
      checker.add_info("📖 Migration guide: https://reactonrails.com/docs/guides/upgrading-react-on-rails")
    end

    def check_breaking_changes_warnings
      return unless defined?(ReactOnRails::VERSION)

      # Parse version - handle pre-release versions like "16.0.0.beta.1"
      current_version = ReactOnRails::VERSION.split(".").map(&:to_i)
      major_version = current_version[0]

      # Check for major version breaking changes
      if major_version >= 16
        check_v16_breaking_changes
      elsif major_version >= 14
        check_v14_breaking_changes
      end
    end

    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def check_v16_breaking_changes
      issues_found = []

      # Check for Webpacker usage (breaking change: removed in v16)
      if File.exist?("config/webpacker.yml") || File.exist?("bin/webpacker")
        issues_found << "• Webpacker support removed - migrate to Shakapacker >= 6.0"
      end

      # Check for CommonJS require() usage (breaking change: ESM-only)
      commonjs_files = []
      begin
        # Check JavaScript/TypeScript files for require() usage
        js_files = Dir.glob(%w[app/javascript/**/*.{js,ts,jsx,tsx} client/**/*.{js,ts,jsx,tsx}])
        js_files.each do |file|
          next unless File.exist?(file)

          content = File.read(file)
          commonjs_files << file if content.match?(/require\s*\(\s*['"]react-on-rails['"]/)
        end
      rescue StandardError
        # Ignore file read errors
      end

      unless commonjs_files.empty?
        issues_found << "• CommonJS require() found - update to ESM imports"
        issues_found << "  Files: #{commonjs_files.take(3).join(', ')}#{'...' if commonjs_files.length > 3}"
      end

      # Check Node.js version (recommendation, not breaking)
      begin
        stdout, _stderr, status = Open3.capture3("node", "--version")
        if status.success?
          node_version = stdout.strip.gsub(/^v/, "")
          version_parts = node_version.split(".").map(&:to_i)
          major = version_parts[0]
          minor = version_parts[1] || 0

          if major < 20 || (major == 20 && minor < 19)
            issues_found << "• Node.js #{node_version} detected - v20.19.0+ recommended for full ESM support"
          end
        end
      rescue StandardError
        # Ignore version check errors
      end

      return if issues_found.empty?

      checker.add_info("\n🚨 React on Rails v16+ Breaking Changes Detected:")
      issues_found.each { |issue| checker.add_warning("  #{issue}") }
      checker.add_info("📖 Full migration guide: https://reactonrails.com/docs/guides/upgrading-react-on-rails#upgrading-to-version-16")
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

    def check_v14_breaking_changes
      checker.add_info("\n📋 React on Rails v14+ Notes:")
      checker.add_info("  • Enhanced React Server Components (RSC) support available in Pro")
      checker.add_info("  • Improved component loading strategies")
      checker.add_info("  • Modern React patterns recommended")
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

    def check_test_helper_setup
      framework_status = test_helper_status_by_framework

      if framework_status.empty?
        checker.add_info(
          "ℹ️  No test helper files found (spec/rails_helper.rb, spec/spec_helper.rb, " \
          "test/test_helper.rb) - skipping test helper check"
        )
        return
      end

      checker.add_info("ℹ️  ReactOnRails::TestHelper is optional unless using build_test_command")

      framework_status.each do |framework, status|
        if status[:configured]
          checker.add_success(
            "✅ ReactOnRails TestHelper configured for #{framework_name(framework)} in #{status[:path]}"
          )
        else
          checker.add_info("ℹ️  ReactOnRails TestHelper missing for #{framework_name(framework)} in #{status[:path]}")
        end
      end
    end

    def npm_test_script?
      package_json_path = resolved_package_json_path
      return false unless File.exist?(package_json_path)

      begin
        package_json = JSON.parse(File.read(package_json_path))
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
    rescue LoadError, StandardError
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

    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def check_server_bundle_prerender_consistency
      config_path = "config/initializers/react_on_rails.rb"
      return unless File.exist?(config_path)

      checker.add_info("\n🔍 Server Rendering Consistency:")

      begin
        content = File.read(config_path)

        # Check for server bundle configuration
        server_bundle_match = content.match(/config\.server_bundle_js_file\s*=\s*["']([^"']+)["']/)
        server_bundle_set = server_bundle_match && server_bundle_match[1].present?

        # Check for global prerender setting
        prerender_match = content.match(/config\.prerender\s*=\s*(true)/)
        prerender_set = prerender_match

        # Check if prerender is used in views
        uses_prerender = uses_prerender_in_views?

        # Analyze the configuration
        if (prerender_set || uses_prerender) && !server_bundle_set
          checker.add_warning("  ⚠️  Server rendering is enabled but server_bundle_js_file is not configured")
          checker.add_info("  💡 Set config.server_bundle_js_file = 'server-bundle.js' to enable SSR")
          checker.add_info("  💡 See: https://reactonrails.com/docs/guides/server-rendering")
        elsif server_bundle_set && !prerender_set && !uses_prerender
          checker.add_info("  ℹ️  server_bundle_js_file is configured but prerender doesn't appear to be used")
          checker.add_info("  💡 Either use prerender: true in react_component calls or remove server_bundle_js_file")
        else
          checker.add_success("  ✅ Server rendering configuration is consistent")
        end
      rescue StandardError => e
        checker.add_warning("  ⚠️  Could not analyze server rendering configuration: #{e.message}")
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

    def uses_prerender_in_views?
      # Check view files for prerender: true
      view_files = Dir.glob("app/views/**/*.{erb,haml,slim}")
      view_files.any? do |file|
        next unless File.exist?(file)

        File.read(file).match?(/prerender:\s*true/)
      end
    rescue StandardError
      false
    end

    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/BlockNesting
    def check_build_test_configuration
      config_path = "config/initializers/react_on_rails.rb"
      shakapacker_yml = shakapacker_config_path

      return unless File.exist?(config_path)

      checker.add_info("\n🧪 Test Asset Compilation:")
      @test_output_path_strategy = :unknown

      begin
        config_content = File.read(config_path)
        has_build_test_command = config_content.match(/^\s*config\.build_test_command\s*=\s*["']([^"']+)["']/)
        framework_status = test_helper_status_by_framework
        configured_frameworks = configured_test_frameworks(framework_status)
        missing_frameworks = missing_test_helper_frameworks(framework_status)

        if File.exist?(shakapacker_yml)
          shakapacker_content = File.read(shakapacker_yml)
          shakapacker_config = parse_shakapacker_config(shakapacker_content)
          check_test_public_output_path_workflow(shakapacker_content, shakapacker_config)
          check_private_output_path_watcher_overlap(shakapacker_content, shakapacker_config)

          has_compile_true = compile_true_for_test_env?(shakapacker_content, shakapacker_config)
          conflicting_test_config = has_build_test_command && has_compile_true

          testing_config_url =
            "https://github.com/shakacode/react_on_rails/blob/master/" \
            "docs/oss/building-features/testing-configuration.md"

          if conflicting_test_config
            checker.add_warning("  ⚠️  Both build_test_command and shakapacker compile: true are configured")
            checker.add_info("  💡 These are mutually exclusive - use only one approach")
            checker.add_info("  💡 Recommended: Use build_test_command with ReactOnRails::TestHelper")
            checker.add_info("  💡 Alternative: Use compile: true in shakapacker.yml (simpler, less explicit)")
            if fix
              if update_test_compile_to_false(shakapacker_yml)
                checker.add_success("  ✅ FIX=true: Updated config/shakapacker.yml test.compile to false")
                has_compile_true = false
              else
                checker.add_warning("  ⚠️  FIX=true: Could not update config/shakapacker.yml automatically")
              end
            else
              checker.add_info("  💡 To auto-fix to the recommended path, run: FIX=true rake react_on_rails:doctor")
            end
            checker.add_info("  📖 See: #{testing_config_url}")
          end

          if has_build_test_command && framework_status.empty? && !conflicting_test_config
            checker.add_warning("  ⚠️  build_test_command is set but no test helper files were found")
            checker.add_info(
              "  💡 Expected one or more of: spec/rails_helper.rb, spec/spec_helper.rb, test/test_helper.rb"
            )
            checker.add_info("  💡 Or remove build_test_command and use compile: true in shakapacker.yml")
          elsif has_build_test_command && missing_frameworks.any? && !conflicting_test_config
            checker.add_warning(
              "  ⚠️  build_test_command is set but ReactOnRails::TestHelper is missing for " \
              "#{framework_names(missing_frameworks)}"
            )
            add_test_helper_setup_guidance(missing_frameworks, framework_status)

            if fix
              fixed_frameworks = fix_missing_test_helpers(missing_frameworks, framework_status)
              if fixed_frameworks.any?
                checker.add_success(
                  "  ✅ FIX=true: Added ReactOnRails::TestHelper wiring for #{framework_names(fixed_frameworks)}"
                )
              else
                checker.add_warning("  ⚠️  FIX=true: Could not auto-update test helper files")
              end
            else
              checker.add_info("  💡 To auto-fix helper wiring, run: FIX=true rake react_on_rails:doctor")
            end

            checker.add_info("  💡 Or remove build_test_command and use compile: true in shakapacker.yml")
          elsif !has_build_test_command && configured_frameworks.any?
            checker.add_error("  🚫 ReactOnRails::TestHelper is configured but build_test_command is not set")
            checker.add_info("  💡 Add to config/initializers/react_on_rails.rb:")
            checker.add_info("      #{DEFAULT_BUILD_TEST_COMMAND}")
            checker.add_info("  💡 Or remove TestHelper and use compile: true in shakapacker.yml")

            if fix
              if add_default_build_test_command(config_path)
                checker.add_success("  ✅ FIX=true: Added build_test_command to config/initializers/react_on_rails.rb")
              else
                checker.add_warning("  ⚠️  FIX=true: Could not auto-update config/initializers/react_on_rails.rb")
              end
            else
              checker.add_info("  💡 To auto-add build_test_command, run: FIX=true rake react_on_rails:doctor")
            end
          elsif !has_build_test_command && !has_compile_true && configured_frameworks.empty?
            checker.add_warning("  ⚠️  No test asset compilation configured")
            checker.add_info("  💡 Recommended: Add to config/initializers/react_on_rails.rb:")
            checker.add_info("      #{DEFAULT_BUILD_TEST_COMMAND}")
            if framework_status.empty?
              checker.add_info("  💡 Then wire ReactOnRails::TestHelper into your test framework")
            else
              add_test_helper_setup_guidance(framework_status.keys, framework_status)
            end

            if fix && !framework_status.empty?
              command_added = add_default_build_test_command(config_path)
              fixed_frameworks = fix_missing_test_helpers(framework_status.keys, framework_status)

              if command_added || fixed_frameworks.any?
                checker.add_success("  ✅ FIX=true: Applied recommended build_test_command + TestHelper setup")
              else
                checker.add_warning("  ⚠️  FIX=true: Could not auto-apply recommended test setup")
              end
            elsif !framework_status.empty?
              checker.add_info("  💡 To auto-apply the recommended setup, run: FIX=true rake react_on_rails:doctor")
            end
            checker.add_info("  📖 See: #{testing_config_url}")
          elsif has_compile_true && !has_build_test_command
            checker.add_success("  ✅ Test assets configured via Shakapacker auto-compilation")
            checker.add_info("      (compile: true in shakapacker.yml)")
            checker.add_info(
              "  💡 For explicit pre-test compilation (recommended for SSR), " \
              "use build_test_command + ReactOnRails::TestHelper"
            )
          elsif has_build_test_command && missing_frameworks.empty? && configured_frameworks.any?
            checker.add_success("  ✅ Test assets configured via React on Rails test helper")
            checker.add_info("      (build_test_command + ReactOnRails::TestHelper)")
          end
        else
          checker.add_warning("  ⚠️  #{shakapacker_yml} not found")
        end
      rescue StandardError => e
        checker.add_warning("  ⚠️  Could not analyze test configuration: #{e.message}")
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/BlockNesting

    def uses_react_on_rails_test_helper?
      test_helper_status_by_framework.values.any? { |status| status[:configured] }
    rescue StandardError
      false
    end

    def shakapacker_config_path
      ENV["SHAKAPACKER_CONFIG"] || DEFAULT_SHAKAPACKER_CONFIG_PATH
    end

    def check_test_public_output_path_workflow(shakapacker_content, shakapacker_config = nil)
      development_output_path = extract_env_config_value(
        shakapacker_content,
        "development",
        "public_output_path",
        shakapacker_config
      )
      test_output_path = extract_env_config_value(shakapacker_content, "test", "public_output_path", shakapacker_config)

      return unless development_output_path && test_output_path

      checker.add_info("  development.public_output_path: #{development_output_path}")
      checker.add_info("  test.public_output_path: #{test_output_path}")

      if development_output_path == test_output_path
        @test_output_path_strategy = :shared
        checker.add_warning("  ⚠️  test and development share public_output_path '#{test_output_path}'")
        checker.add_info("  💡 Shared output is an advanced workflow meant for bin/dev static")
        checker.add_info("  💡 Do not use shared output with bin/dev (HMR): manifests can collide")
        add_shared_output_path_procfile_guidance
      else
        @test_output_path_strategy = :separate
        checker.add_success("  ✅ test and development use separate public_output_path values (recommended)")
        checker.add_info("  💡 Separate output paths prevent manifest collisions across test and development")
      end
    end

    def add_shared_output_path_procfile_guidance
      return unless hmr_procfile_configured?

      if static_procfile_available?
        checker.add_warning(
          "  ⚠️  HMR Procfile.dev is present. Shared output path is high-risk unless you run bin/dev static."
        )
        checker.add_info("  💡 Use: ./bin/dev static")
        checker.add_info("  💡 For test watch in this setup: ./bin/dev test-watch --test-watch-mode=client-only")
      else
        checker.add_error(
          "  🚫 Shared output path + HMR Procfile.dev detected, but Procfile.dev-static-assets is missing"
        )
        checker.add_info("  💡 Fix: separate test/development public_output_path values, or add static Procfile support")
      end
    end

    def hmr_procfile_configured?
      return false unless File.exist?("Procfile.dev")

      File.read("Procfile.dev").include?("shakapacker-dev-server")
    rescue StandardError
      false
    end

    def static_procfile_available?
      return false unless File.exist?("Procfile.dev-static-assets")

      File.read("Procfile.dev-static-assets").include?("bin/shakapacker --watch")
    rescue StandardError
      false
    end

    def check_private_output_path_watcher_overlap(shakapacker_content, shakapacker_config = nil)
      default_private = extract_env_config_value(
        shakapacker_content,
        "default",
        "private_output_path",
        shakapacker_config
      )
      development_private = extract_env_config_value(
        shakapacker_content,
        "development",
        "private_output_path",
        shakapacker_config
      ) || default_private
      test_private = extract_env_config_value(
        shakapacker_content,
        "test",
        "private_output_path",
        shakapacker_config
      ) || default_private

      return unless development_private && test_private
      return unless development_private == test_private

      checker.add_info("  development.private_output_path: #{development_private}")
      checker.add_info("  test.private_output_path: #{test_private}")
      checker.add_info(
        "  💡 Server bundles share this path; full dev/test watchers can duplicate server-bundle rebuilds"
      )
      checker.add_info("  💡 Use ./bin/dev test-watch to auto-select full vs client-only test watch mode")
    end

    # Warns when development and test share public_output_path AND HMR is enabled,
    # but only if the project uses Capybara in standard server mode (where Capybara
    # starts its own Puma and reads assets from the filesystem).
    #
    # This is NOT a problem when:
    # - Only using Playwright/Cypress E2E (browser connects to running dev server)
    # - Capybara uses run_server = false (browser connects to running dev server)
    # - Only running request/controller specs (no browser, no manifest lookup)
    # - No Capybara at all
    def check_shared_output_paths_with_hmr
      return unless @test_output_path_strategy == :shared
      return unless hmr_enabled_in_shakapacker?
      return unless capybara_uses_own_server?

      checker.add_warning(
        "  ⚠️  Shared output paths with dev_server.hmr: true detected"
      )
      checker.add_info(
        "  💡 HMR manifests contain http:// URLs that break Capybara system tests"
      )
      checker.add_info(
        "  💡 This does NOT affect Playwright/Cypress E2E or Capybara with run_server = false"
      )
      checker.add_info(
        "  💡 Fix: use separate public_output_path values for development and test,"
      )
      checker.add_info(
        "     or only run bin/dev static (not bin/dev) when running Capybara tests"
      )
      checker.add_info(
        "  📖 See: https://github.com/shakacode/react_on_rails/blob/master/" \
        "docs/oss/building-features/dev-server-and-testing.md"
      )
    end

    def hmr_enabled_in_shakapacker?
      shakapacker_yml = shakapacker_config_path
      return false unless File.exist?(shakapacker_yml)

      shakapacker_config = parse_shakapacker_config(File.read(shakapacker_yml))
      return false unless shakapacker_config.is_a?(Hash)

      dev_config = (shakapacker_config["default"] || {}).merge(shakapacker_config["development"] || {})
      dev_server = dev_config["dev_server"]
      return false unless dev_server.is_a?(Hash)

      dev_server["hmr"].to_s == "true"
    end

    # Returns true if Capybara is configured but NOT in external server mode.
    # External server mode (run_server = false) connects to a running dev server,
    # so HMR manifests work fine — the browser fetches assets through the full stack.
    def capybara_uses_own_server?
      helper_files = RSPEC_HELPER_FILES + [MINITEST_HELPER_FILE]
      helper_files.any? do |file|
        next false unless File.exist?(file)

        content = File.read(file)
        next false unless content.match?(/capybara/i)

        # If run_server = false, Capybara connects to external server (HMR works)
        !content.match?(/Capybara\.run_server\s*=\s*false/)
      end
    rescue StandardError
      false
    end

    # Detects Minitest system tests (ActionDispatch::SystemTestCase) and checks
    # that ensure_assets_compiled is wired into test/test_helper.rb.
    def check_minitest_system_test_wiring
      system_test_file = "test/application_system_test_case.rb"
      test_helper_file = MINITEST_HELPER_FILE
      return unless File.exist?(system_test_file)

      checker.add_info("\n🧪 Minitest System Tests:")

      unless File.exist?(test_helper_file)
        checker.add_warning("  ⚠️  #{system_test_file} found but #{test_helper_file} is missing")
        return
      end

      content = File.read(test_helper_file)
      if helper_call_present?(content, "ensure_assets_compiled")
        checker.add_success("  ✅ Minitest system tests detected with ensure_assets_compiled wired in")
      else
        warn_missing_minitest_system_test_helper(system_test_file, test_helper_file)
      end
    rescue StandardError => e
      checker.add_warning("  ⚠️  Could not check Minitest system test setup: #{e.message}")
    end

    def warn_missing_minitest_system_test_helper(system_test_file, test_helper_file)
      checker.add_warning(
        "  ⚠️  #{system_test_file} found but ReactOnRails::TestHelper.ensure_assets_compiled " \
        "is not called in #{test_helper_file}"
      )
      checker.add_info("  💡 Add to #{test_helper_file}:")
      checker.add_info("      require 'react_on_rails/test_helper'")
      checker.add_info("      ActiveSupport::TestCase.setup do")
      checker.add_info("        ReactOnRails::TestHelper.ensure_assets_compiled")
      checker.add_info("      end")

      if fix
        if ensure_minitest_test_helper_setup(test_helper_file)
          checker.add_success("  ✅ FIX=true: Added ensure_assets_compiled to #{test_helper_file}")
        else
          checker.add_warning("  ⚠️  FIX=true: Could not auto-update #{test_helper_file}")
        end
      else
        checker.add_info("  💡 To auto-fix, run: FIX=true rake react_on_rails:doctor")
      end
    end

    # Detects Capybara configuration patterns that affect how tests interact with
    # webpack assets and dev servers. Reports custom driver setups as informational
    # context (users often have bespoke Capybara configurations).
    def check_capybara_external_server_mode
      helper_files = RSPEC_HELPER_FILES + [MINITEST_HELPER_FILE]
      found_external_server = false

      helper_files.each do |file|
        next unless File.exist?(file)

        content = File.read(file)
        report_capybara_custom_drivers(file, content)
        next unless content.match?(/Capybara\.run_server\s*=\s*false/)

        found_external_server = true
        report_capybara_external_server(file)
        break
      end

      report_capybara_standard_mode unless found_external_server
    rescue StandardError
      # Non-critical check, skip silently
    end

    def report_capybara_custom_drivers(file, content)
      drivers = content.scan(/Capybara\.register_driver\s+:(\w+)/).flatten
      return if drivers.empty?

      checker.add_info("\n🔧 Capybara Drivers (#{file}):")
      checker.add_info("  ℹ️  Custom drivers registered: #{drivers.map { |d| ":#{d}" }.join(', ')}")

      return unless @test_output_path_strategy == :shared

      checker.add_info(
        "  💡 With shared output paths, only use bin/dev static (not HMR) when running Capybara tests"
      )
    end

    def report_capybara_external_server(file)
      checker.add_info("\n🔗 External Server Mode:")
      checker.add_info(
        "  ℹ️  #{file} sets Capybara.run_server = false (external server mode)"
      )
      checker.add_info(
        "  💡 Tests require bin/dev (or another server) to be running at the configured app_host"
      )
      checker.add_info(
        "  💡 Both bin/dev (HMR) and bin/dev static work in this mode"
      )
    end

    def report_capybara_standard_mode
      return unless capybara_configured?

      checker.add_info(
        "  💡 Capybara starts its own server — HMR assets won't work. Use bin/dev static or precompile."
      )
    end

    def capybara_configured?
      helper_files = RSPEC_HELPER_FILES + [MINITEST_HELPER_FILE]
      helper_files.any? do |file|
        File.exist?(file) && File.read(file).match?(/capybara/i)
      end
    rescue StandardError
      false
    end

    def extract_env_config_value(content, env_name, key, shakapacker_config = nil)
      return extract_env_config_value_from_hash(shakapacker_config, env_name, key) if shakapacker_config.is_a?(Hash)

      parsed_config = parse_shakapacker_config(content)
      return nil unless parsed_config.is_a?(Hash)

      extract_env_config_value_from_hash(parsed_config, env_name, key)
    end

    def extract_env_config_value_from_hash(config, env_name, key)
      default_config = config["default"] || {}
      env_config = config[env_name] || {}
      merged_config = default_config.merge(env_config)
      normalize_yaml_scalar(merged_config[key].to_s) if merged_config.key?(key)
    end

    def parse_shakapacker_config(content)
      parsed = YAML.safe_load(ERB.new(content).result, permitted_classes: [Symbol], aliases: true)
      parsed.is_a?(Hash) ? parsed : nil
    rescue StandardError
      nil
    end

    def compile_true_for_test_env?(content, shakapacker_config)
      if shakapacker_config.is_a?(Hash)
        test_compile_value = extract_env_config_value_from_hash(shakapacker_config, "test", "compile")
        test_compile_value.to_s == "true"
      else
        content.match?(/^test:.*?^\s+compile:\s*true/m)
      end
    end

    def normalize_yaml_scalar(value)
      value.to_s.strip.gsub(/\A['"]|['"]\z/, "")
    end

    def test_helper_status_by_framework
      status = {}

      rspec_status = rspec_helper_status
      status[:rspec] = rspec_status if rspec_status

      if File.exist?(MINITEST_HELPER_FILE)
        content = File.read(MINITEST_HELPER_FILE)
        status[:minitest] = {
          path: MINITEST_HELPER_FILE,
          configured: helper_call_present?(content, "ensure_assets_compiled")
        }
      end

      status
    rescue StandardError
      {}
    end

    def rspec_helper_status
      rspec_files = RSPEC_HELPER_FILES.select { |file| File.exist?(file) }
      return nil unless rspec_files.any?

      rspec_statuses = rspec_files.map do |file|
        content = File.read(file)
        { path: file, configured: helper_call_present?(content, "configure_rspec_to_compile_assets") }
      end
      configured_status = rspec_statuses.find { |helper_status| helper_status[:configured] }

      {
        path: configured_status&.dig(:path) || rspec_statuses.first[:path],
        configured: rspec_statuses.any? { |helper_status| helper_status[:configured] }
      }
    end

    def preferred_rspec_helper_file
      RSPEC_HELPER_FILES.find { |file| File.exist?(file) }
    end

    def helper_call_present?(content, method_name)
      content.match?(/^\s*(?!#).*\b#{Regexp.escape(method_name)}\b/)
    end

    def configured_test_frameworks(framework_status)
      framework_status.filter_map { |framework, status| framework if status[:configured] }
    end

    def missing_test_helper_frameworks(framework_status)
      framework_status.filter_map { |framework, status| framework unless status[:configured] }
    end

    def framework_names(frameworks)
      frameworks.map { |framework| framework_name(framework) }.join(", ")
    end

    def framework_name(framework)
      framework == :rspec ? "RSpec" : "Minitest"
    end

    def add_test_helper_setup_guidance(frameworks, framework_status)
      frameworks.each do |framework|
        path = framework_status.dig(framework, :path) || fallback_path_for_framework(framework)
        checker.add_info("  💡 Add to #{path}:")
        checker.add_info("      require 'react_on_rails/test_helper'")
        if framework == :rspec
          checker.add_info("      ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)")
        else
          checker.add_info("      ReactOnRails::TestHelper.ensure_assets_compiled")
        end
      end
    end

    def fallback_path_for_framework(framework)
      return "spec/rails_helper.rb" if framework == :rspec

      MINITEST_HELPER_FILE
    end

    def fix_missing_test_helpers(frameworks, framework_status)
      fixed_frameworks = []

      frameworks.each do |framework|
        path = framework_status.dig(framework, :path)
        next unless path

        fixed = case framework
                when :rspec
                  ensure_rspec_test_helper_setup(path)
                when :minitest
                  ensure_minitest_test_helper_setup(path)
                else
                  false
                end

        fixed_frameworks << framework if fixed
      end

      fixed_frameworks
    end

    def ensure_rspec_test_helper_setup(file_path)
      content = File.read(file_path)
      return true if helper_call_present?(content, "configure_rspec_to_compile_assets")

      updated_content = ensure_require_statement(content, "react_on_rails/test_helper", /^\s*RSpec\.configure/)

      rspec_block = <<~RUBY.chomp
        RSpec.configure do |config|
          # Ensure that tests run against fresh webpack assets.
          ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
        end
      RUBY
      existing_rspec_block_injection = <<~RUBY
        # Ensure that tests run against fresh webpack assets.
        ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
      RUBY

      updated_content = if updated_content.match?(/^\s*RSpec\.configure\s+do\s+\|config\|/)
                          updated_content.sub(
                            /^(\s*RSpec\.configure\s+do\s+\|config\|\s*\n)/,
                            "\\1#{existing_rspec_block_injection}"
                          )
                        else
                          "#{updated_content.rstrip}\n\n#{rspec_block}\n"
                        end

      File.write(file_path, updated_content)
      true
    rescue StandardError
      false
    end

    def ensure_minitest_test_helper_setup(file_path)
      content = File.read(file_path)
      return true if helper_call_present?(content, "ensure_assets_compiled")

      updated_content = ensure_require_statement(
        content,
        "react_on_rails/test_helper",
        /^\s*class\s+ActiveSupport::TestCase/
      )
      minitest_block = <<~RUBY
        # Ensure that tests run against fresh webpack assets.
        ActiveSupport::TestCase.setup do
          ReactOnRails::TestHelper.ensure_assets_compiled
        end
      RUBY
      updated_content = "#{updated_content.rstrip}\n\n#{minitest_block}"
      File.write(file_path, updated_content)
      true
    rescue StandardError
      false
    end

    def ensure_require_statement(content, require_path, before_pattern = nil)
      return content if content.match?(/^\s*require\s+["']#{Regexp.escape(require_path)}["']/)

      require_line = "require \"#{require_path}\"\n"
      return "#{content.rstrip}\n#{require_line}\n" unless before_pattern

      match = content.match(before_pattern)
      return "#{content.rstrip}\n#{require_line}\n" unless match

      insert_position = match.begin(0)
      "#{content[0...insert_position]}#{require_line}#{content[insert_position..]}"
    end

    def add_default_build_test_command(config_path)
      content = File.read(config_path)
      return true if content.match?(/^\s*config\.build_test_command\s*=\s*["'][^"']+["']/)

      build_test_line = "  #{DEFAULT_BUILD_TEST_COMMAND}"
      updated_content = if content.match?(/\nend\s*\z/)
                          content.sub(/\nend\s*\z/, "\n#{build_test_line}\nend\n")
                        else
                          "#{content.rstrip}\n#{build_test_line}\n"
                        end

      File.write(config_path, updated_content)
      true
    rescue StandardError
      false
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    def update_test_compile_to_false(shakapacker_path)
      content = File.read(shakapacker_path)
      lines = content.lines

      in_test_section = false
      test_indent = 0
      changed = false

      lines.each_with_index do |line, index|
        if (match = line.match(/^(\s*)test:\s*(?:#.*)?$/))
          in_test_section = true
          test_indent = match[1].length
          next
        end

        next unless in_test_section
        next if line.strip.empty?

        current_indent = line[/^\s*/].size
        if current_indent <= test_indent
          in_test_section = false
          next
        end

        compile_match = line.match(/^(\s*compile:\s*)true(\s*(?:#.*)?)$/)
        next unless compile_match

        lines[index] = "#{compile_match[1]}false#{compile_match[2]}\n"
        changed = true
        break
      end

      return false unless changed

      File.write(shakapacker_path, lines.join)
      true
    rescue StandardError
      false
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    def relativize_path(absolute_path)
      return absolute_path unless absolute_path.is_a?(String)

      project_root = Dir.pwd
      if absolute_path.start_with?(project_root)
        # Remove project root and leading slash to make it relative
        relative = absolute_path.sub(project_root, "").sub(%r{^/}, "")
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

    # Comment patterns used for filtering out commented async usage
    ERB_COMMENT_PATTERN = /<%\s*#.*javascript_pack_tag/
    HAML_COMMENT_PATTERN = /^\s*-#.*javascript_pack_tag/
    SLIM_COMMENT_PATTERN = %r{^\s*/.*javascript_pack_tag}
    HTML_COMMENT_PATTERN = /<!--.*javascript_pack_tag/

    def check_async_usage
      # When Pro is installed, async is fully supported and is the default behavior
      # No need to check for async usage in this case
      return if ReactOnRails::Utils.react_on_rails_pro?

      async_issues = []

      # Check 1: javascript_pack_tag with :async in view files
      view_files_with_async = scan_view_files_for_async_pack_tag
      unless view_files_with_async.empty?
        async_issues << "javascript_pack_tag with :async found in view files:"
        view_files_with_async.each do |file|
          async_issues << "  • #{file}"
        end
      end

      # Check 2: generated_component_packs_loading_strategy = :async
      if config_has_async_loading_strategy?
        async_issues << "config.generated_component_packs_loading_strategy = :async in initializer"
      end

      return if async_issues.empty?

      # Report errors if async usage is found without Pro
      checker.add_error("🚫 :async usage detected without React on Rails Pro")
      async_issues.each { |issue| checker.add_error("  #{issue}") }
      checker.add_info("  💡 :async can cause race conditions. Options:")
      checker.add_info("    1. Upgrade to React on Rails Pro (recommended for :async support)")
      checker.add_info("    2. Change to :defer or :sync loading strategy")
      checker.add_info("  📖 https://reactonrails.com/docs/guides/configuration/")
    end

    def scan_view_files_for_async_pack_tag
      view_patterns = ["app/views/**/*.erb", "app/views/**/*.haml", "app/views/**/*.slim"]
      files_with_async = view_patterns.flat_map { |pattern| scan_pattern_for_async(pattern) }
      files_with_async.compact
    rescue Errno::ENOENT, Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError => e
      # Log the error if Rails logger is available
      log_debug("Error scanning view files for async: #{e.message}")
      []
    end

    def scan_pattern_for_async(pattern)
      Dir.glob(pattern).filter_map do |file|
        next unless File.exist?(file)

        content = File.read(file)
        next if content_has_only_commented_async?(content)
        next unless file_has_async_pack_tag?(content)

        relativize_path(file)
      end
    end

    def file_has_async_pack_tag?(content)
      # Match javascript_pack_tag with :async symbol or async: true hash syntax
      # Examples that should match:
      #   - javascript_pack_tag "app", :async
      #   - javascript_pack_tag "app", async: true
      #   - javascript_pack_tag "app", :async, other_option: value
      # Examples that should NOT match:
      #   - javascript_pack_tag "app", defer: "async" (async is a string value, not the option)
      #   - javascript_pack_tag "app", :defer
      # Note: Theoretical edge case `data: { async: true }` would match but is extremely unlikely
      # in real code and represents a harmless false positive (showing a warning when not needed)
      # Use word boundary \b to ensure :async is not part of a longer symbol like :async_mode
      # [^<]* allows matching across newlines within ERB tags but stops at closing ERB tag
      content.match?(/javascript_pack_tag[^<]*(?::async\b|async:\s*true)/)
    end

    def content_has_only_commented_async?(content)
      # Check if all occurrences of javascript_pack_tag with :async are in comments
      # Returns true if ONLY commented async usage exists (no active async usage)

      # First check if there's any javascript_pack_tag with :async in the full content
      return true unless file_has_async_pack_tag?(content)

      # Strategy: Remove all commented lines, then check if any :async remains
      # This handles both single-line and multi-line tags correctly
      uncommented_lines = content.each_line.reject do |line|
        line.match?(ERB_COMMENT_PATTERN) ||
          line.match?(HAML_COMMENT_PATTERN) ||
          line.match?(SLIM_COMMENT_PATTERN) ||
          line.match?(HTML_COMMENT_PATTERN)
      end

      uncommented_content = uncommented_lines.join
      # If no async found in uncommented content, all async usage was commented
      !file_has_async_pack_tag?(uncommented_content)
    end

    def config_has_async_loading_strategy?
      config_path = "config/initializers/react_on_rails.rb"
      return false unless File.exist?(config_path)

      content = File.read(config_path)
      # Check if generated_component_packs_loading_strategy is set to :async
      # Filter out commented lines (lines starting with # after optional whitespace)
      content.each_line.any? do |line|
        # Skip lines that start with # (after optional whitespace)
        next if line.match?(/^\s*#/)

        # Match: config.generated_component_packs_loading_strategy = :async
        # Use word boundary \b to ensure :async is the complete symbol, not part of :async_mode etc.
        line.match?(/config\.generated_component_packs_loading_strategy\s*=\s*:async\b/)
      end
    rescue Errno::ENOENT, Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError => e
      # Log the error if Rails logger is available
      log_debug("Error checking async loading strategy: #{e.message}")
      false
    end

    def log_debug(message)
      Rails.logger&.debug(message)
    end

    # Check Shakapacker private_output_path integration and provide recommendations
    def check_shakapacker_private_output_path(rails_bundle_path)
      return report_no_shakapacker unless defined?(::Shakapacker)
      return report_upgrade_shakapacker unless ::Shakapacker.config.respond_to?(:private_output_path)

      check_shakapacker_9_private_output_path(rails_bundle_path)
    rescue StandardError => e
      checker.add_info("\n  ℹ️  Could not check Shakapacker config: #{e.message}")
    end

    def report_no_shakapacker
      checker.add_info("\n  ℹ️  Shakapacker not detected - using manual configuration")
    end

    def report_upgrade_shakapacker
      checker.add_info(<<~MSG.strip)
        \n  💡 Recommendation: Upgrade to Shakapacker 9.0+

        Shakapacker 9.0+ adds 'private_output_path' in shakapacker.yml for server bundles.
        This eliminates the need to configure server_bundle_output_path separately.

        Benefits:
        - Single source of truth in shakapacker.yml
        - Automatic detection by React on Rails
        - No configuration duplication
      MSG
    end

    def check_shakapacker_9_private_output_path(rails_bundle_path)
      private_path = ::Shakapacker.config.private_output_path

      if private_path
        report_shakapacker_path_status(private_path, rails_bundle_path)
      else
        report_configure_private_output_path(rails_bundle_path)
      end
    end

    def report_shakapacker_path_status(private_path, rails_bundle_path)
      relative_path = ReactOnRails::Utils.normalize_to_relative_path(private_path)
      # Normalize both paths for comparison (remove trailing slashes)
      normalized_relative = relative_path.to_s.chomp("/")
      normalized_rails = rails_bundle_path.to_s.chomp("/")

      if normalized_relative == normalized_rails
        checker.add_success("\n  ✅ Using Shakapacker 9.0+ private_output_path: '#{relative_path}'")
        checker.add_info("     Auto-detected from shakapacker.yml - no manual config needed")
      else
        report_configuration_mismatch(relative_path, rails_bundle_path)
      end
    end

    def report_configuration_mismatch(relative_path, rails_bundle_path)
      checker.add_warning(<<~MSG.strip)
        \n  ⚠️  Configuration mismatch detected!

        Shakapacker private_output_path: '#{relative_path}'
        React on Rails server_bundle_output_path: '#{rails_bundle_path}'

        Recommendation: Remove server_bundle_output_path from your React on Rails
        initializer and let it auto-detect from shakapacker.yml private_output_path.
      MSG
    end

    def report_configure_private_output_path(rails_bundle_path)
      checker.add_info(<<~MSG.strip)
        \n  💡 Recommendation: Configure private_output_path in shakapacker.yml

        Add to config/shakapacker.yml:
          private_output_path: #{rails_bundle_path}

        This will:
        - Keep webpack and Rails configs in sync automatically
        - Enable auto-detection by React on Rails
        - Serve as single source of truth for server bundle location
      MSG
    end
    # ── Helpers for Pro/RSC checks ────────────────────────────────────

    # Lazily load the Rails environment so that initializers (which configure
    # ReactOnRailsPro) have run before we read Pro/RSC config values.
    # Safe to call multiple times — only loads once.
    # Returns true if environment was loaded successfully, false otherwise.
    def ensure_rails_environment_loaded
      return true if @rails_environment_loaded
      return false if @rails_environment_attempted

      @rails_environment_attempted = true

      env_file = "config/environment.rb"
      return false unless File.exist?(env_file)

      require File.expand_path(env_file)
      @rails_environment_loaded = true
    rescue StandardError, LoadError => e
      checker.add_warning(<<~MSG.strip)
        ⚠️  Could not load Rails environment: #{e.message}

        Pro/RSC diagnostics may reflect default values instead of your app's configuration.
      MSG
      false
    end

    # Resolve the JavaScript source path from Shakapacker config.
    # Falls back to "app/javascript" if Shakapacker is not available.
    def resolve_js_source_path
      require "shakapacker"
      Shakapacker.config.source_path.to_s
    rescue LoadError, StandardError
      shakapacker_yml_source_path || "app/javascript"
    end

    def shakapacker_yml_source_path
      config_path = "config/shakapacker.yml"
      return nil unless File.exist?(config_path)

      config = parse_shakapacker_config(File.read(config_path))
      return nil unless config.is_a?(Hash)

      default_config = config["default"] || {}
      normalize_yaml_scalar(default_config["source_path"]) if default_config.key?("source_path")
    rescue StandardError
      nil
    end

    # ── React on Rails Pro Setup ──────────────────────────────────────

    def check_pro_setup
      return unless ReactOnRails::Utils.react_on_rails_pro?

      check_pro_initializer_existence
      ensure_rails_environment_loaded
      check_pro_renderer_mode
      check_base_package_imports
    end

    def check_pro_initializer_existence
      initializer_path = "config/initializers/react_on_rails_pro.rb"
      if File.exist?(initializer_path)
        checker.add_success("✅ Pro initializer exists (#{initializer_path})")
      else
        checker.add_warning(<<~MSG.strip)
          ⚠️  Pro initializer not found at #{initializer_path}.

          Without this file, React on Rails Pro runs with all default settings.
          Run the Pro generator to create it:
            rails g react_on_rails:pro
        MSG
      end
    end

    def check_pro_renderer_mode
      renderer = ReactOnRailsPro.configuration.server_renderer
      if renderer == "NodeRenderer"
        checker.add_success("✅ Pro renderer: NodeRenderer (dedicated Node.js process)")
      else
        checker.add_info("ℹ️  Pro renderer: #{renderer}")
        checker.add_info("  💡 NodeRenderer provides better performance and is required for RSC")
      end
    rescue StandardError => e
      checker.add_warning("⚠️  Could not detect Pro renderer mode: #{e.message}")
    end

    # The base 'react-on-rails' npm package is a transitive dependency of 'react-on-rails-pro',
    # so `import ... from 'react-on-rails'` resolves silently — loading the base package instead
    # of Pro. Components registered through the base package won't have Pro features (streaming,
    # caching, RSC), and may cause "component not registered" errors at runtime.
    BASE_PACKAGE_IMPORT_PATTERN = %r{\bfrom\s+['"]react-on-rails(?:/[^'"]*)?['"]}
    BASE_PACKAGE_REQUIRE_PATTERN = %r{\brequire\s*\(\s*['"]react-on-rails(?:/[^'"]*)?['"]\s*\)}

    def check_base_package_imports # rubocop:disable Metrics/CyclomaticComplexity
      source_path = resolve_js_source_path
      js_extensions = %w[js jsx ts tsx]
      js_patterns = js_extensions.map { |ext| "#{source_path}/**/*.#{ext}" }
      files_with_base_import = []

      js_patterns.each do |pattern|
        Dir.glob(pattern).each do |file|
          content = File.read(file)
          next unless content.match?(BASE_PACKAGE_IMPORT_PATTERN) || content.match?(BASE_PACKAGE_REQUIRE_PATTERN)

          files_with_base_import << file
        end
      end

      if files_with_base_import.empty?
        checker.add_success("✅ No base 'react-on-rails' imports found (Pro package used correctly)")
      else
        checker.add_warning(<<~MSG.strip)
          ⚠️  Found imports from 'react-on-rails' instead of 'react-on-rails-pro':
          #{files_with_base_import.map { |f| "  • #{f}" }.join("\n")}

          The base package is a transitive dependency of Pro, so these imports resolve
          silently but load the base version without Pro features.

          Fix: Update imports to use 'react-on-rails-pro':
            import ReactOnRails from 'react-on-rails-pro';        // server
            import ReactOnRails from 'react-on-rails-pro/client';  // client
        MSG
      end
    rescue StandardError => e
      checker.add_warning("⚠️  Could not scan for base package imports: #{e.message}")
    end

    # ── React Server Components ────────────────────────────────────

    # Candidate paths for RSC bundler configuration (webpack and rspack variants)
    RSC_BUNDLER_CONFIG_PATHS = %w[
      config/webpack/rscWebpackConfig.js
      config/rspack/rscWebpackConfig.js
    ].freeze

    def check_rsc_setup
      return unless ReactOnRails::Utils.react_on_rails_pro?

      ensure_rails_environment_loaded
      pro_config = ReactOnRailsPro.configuration
      return unless pro_config.enable_rsc_support

      checker.add_info("🔬 React Server Components: enabled")
      checker.add_info("  rsc_bundle_js_file: #{pro_config.rsc_bundle_js_file}")
      checker.add_info("  rsc_payload_generation_url_path: #{pro_config.rsc_payload_generation_url_path}")

      check_rsc_renderer_mode(pro_config)
      check_rsc_payload_route
      check_rsc_bundler_config
      check_rsc_react_version
      check_rsc_procfile_watcher
    rescue StandardError => e
      checker.add_warning("⚠️  RSC setup check encountered an error: #{e.message}")
    end

    def check_rsc_renderer_mode(pro_config)
      return if pro_config.server_renderer == "NodeRenderer"

      checker.add_error(<<~MSG.strip)
        🚫 RSC requires NodeRenderer but current renderer is '#{pro_config.server_renderer}'.

        React Server Components need a dedicated Node.js process for server rendering.

        Fix: Set server_renderer to "NodeRenderer" in config/initializers/react_on_rails_pro.rb:
          config.server_renderer = "NodeRenderer"
      MSG
    end

    def check_rsc_payload_route
      routes_file = "config/routes.rb"

      unless File.exist?(routes_file)
        checker.add_warning("⚠️  config/routes.rb not found — cannot verify RSC payload route")
        return
      end

      routes_content = File.read(routes_file)
      uncommented_route = routes_content.each_line.any? do |line|
        next if line.match?(/^\s*#/)

        line.include?("rsc_payload_route")
      end
      if uncommented_route
        checker.add_success("✅ RSC payload route configured")
      else
        checker.add_error(<<~MSG.strip)
          🚫 RSC payload route not found in config/routes.rb.

          Without this route, React Server Component payload requests will 404.

          Fix: Add to config/routes.rb inside the Rails.application.routes.draw block:
            rsc_payload_route
        MSG
      end
    end

    def check_rsc_bundler_config
      found_path = RSC_BUNDLER_CONFIG_PATHS.find { |path| File.exist?(path) }

      if found_path
        checker.add_success("✅ RSC bundler config exists (#{found_path})")
      else
        checker.add_error(<<~MSG.strip)
          🚫 RSC bundler config not found.

          Expected one of: #{RSC_BUNDLER_CONFIG_PATHS.join(' or ')}

          This file defines the webpack/rspack configuration for the RSC bundle.

          Fix: Run the RSC generator to create it:
            rails g react_on_rails:rsc
        MSG
      end
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    def check_rsc_react_version
      react_version = detect_react_version_from_deps
      unless react_version
        checker.add_info("ℹ️  Could not detect React version — skipping RSC version check")
        return
      end

      major, minor, patch = react_version.split(".").map(&:to_i)

      if major == 19 && minor.zero? && patch >= 4
        checker.add_success("✅ React #{react_version} is compatible with RSC")
      elsif major == 19 && minor.zero?
        checker.add_warning(<<~MSG.strip)
          ⚠️  React #{react_version} has known security vulnerabilities fixed in 19.0.4+.

          Upgrade to at least React 19.0.4:
            npm install react@~19.0.4 react-dom@~19.0.4
        MSG
      elsif major >= 19
        checker.add_warning(<<~MSG.strip)
          ⚠️  React #{react_version} has not been verified with React on Rails Pro RSC.

          RSC support currently targets React 19.0.x. React #{major}.#{minor}.x may work
          but has not been tested. Verified compatibility: React 19.0.4+.
        MSG
      else
        checker.add_error(<<~MSG.strip)
          🚫 React #{react_version} is not compatible with RSC.

          React Server Components in React on Rails Pro requires React 19.x or higher.

          Fix: npm install react@~19.0.4 react-dom@~19.0.4
        MSG
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    def detect_react_version_from_deps
      # Prefer the actually installed version from node_modules over the declared
      # range in package.json. Declared ranges like "^19.0.0" would be misleading
      # (stripped to "19.0.0" even though 19.0.4+ may be installed).
      installed = installed_react_version
      return installed if installed

      declared_react_version
    rescue StandardError
      nil
    end

    def installed_react_version
      # Use Node's own module resolution to find the actually installed React,
      # which handles hoisted dependencies in monorepos and pnpm workspaces.
      stdout, _stderr, status = Open3.capture3("node", "-e",
                                               "console.log(require.resolve('react/package.json'))")
      return nil unless status.success?

      resolved_path = stdout.strip
      return nil if resolved_path.empty? || !File.exist?(resolved_path)

      version = JSON.parse(File.read(resolved_path))["version"]
      version if version&.match?(/\A\d+\.\d+\.\d+/)
    rescue StandardError
      nil
    end

    def declared_react_version
      return nil unless File.exist?("package.json")

      package_json = JSON.parse(File.read("package.json"))
      all_deps = (package_json["dependencies"] || {}).merge(package_json["devDependencies"] || {})
      version_str = all_deps["react"]
      return nil unless version_str

      clean_version = version_str.gsub(/\A[^0-9]*/, "")
      clean_version if clean_version.match?(/\A\d+\.\d+\.\d+\z/)
    rescue StandardError
      nil
    end

    def check_rsc_procfile_watcher
      procfile_path = "Procfile.dev"

      unless File.exist?(procfile_path)
        checker.add_warning("⚠️  Procfile.dev not found — cannot verify RSC bundle watcher")
        checker.add_info("  💡 If using a custom process manager, ensure RSC bundle is built separately")
        return
      end

      uncommented_watcher = File.readlines(procfile_path).any? do |line|
        next if line.match?(/^\s*#/)

        line.include?("RSC_BUNDLE_ONLY")
      end
      if uncommented_watcher
        checker.add_success("✅ RSC bundle watcher configured in Procfile.dev")
      else
        checker.add_warning(<<~MSG.strip)
          ⚠️  RSC bundle watcher not found in Procfile.dev.

          The RSC bundle needs to be built separately from client/server bundles.

          If using Procfile.dev, add:
            rsc-bundle: RSC_BUNDLE_ONLY=yes bin/shakapacker --watch

          If using a custom process manager, ensure the RSC bundle is built with
          the RSC_BUNDLE_ONLY=yes environment variable.
        MSG
      end
    end
  end
  # rubocop:enable Metrics/ClassLength
end

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
      print_doctor_feature_info
      puts
    end

    def print_doctor_feature_info
      puts Rainbow("ℹ️  Doctor Feature Information:").blue
      puts "   • This diagnostic tool is available in React on Rails v16.0.0+"
      puts "   • For older versions, upgrade your gem to access this feature"
      puts "   • Run: bundle update react_on_rails"
      puts "   • Documentation: https://www.shakacode.com/react-on-rails/docs/"
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
        ["Development Environment", :check_development]
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
        "bin/dev" => "Development server launcher",
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

      check_layout_files
      check_server_rendering_engine
    end

    # rubocop:disable Metrics/CyclomaticComplexity
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
    # rubocop:enable Metrics/CyclomaticComplexity

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

    # rubocop:disable Metrics/CyclomaticComplexity
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
    # rubocop:enable Metrics/CyclomaticComplexity

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
        checker.add_info("📍 Documentation: https://www.shakacode.com/react-on-rails/docs/guides/configuration/")

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

    def analyze_server_rendering_config(content)
      checker.add_info("\n🖥️  Server Rendering:")

      # Server bundle file
      server_bundle_match = content.match(/config\.server_bundle_js_file\s*=\s*["']([^"']+)["']/)
      if server_bundle_match
        checker.add_info("  server_bundle_js_file: #{server_bundle_match[1]}")
      else
        checker.add_info("  server_bundle_js_file: server-bundle.js (default)")
      end

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
    # rubocop:enable Metrics/AbcSize

    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
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
        checker.add_info("    ℹ️  See: https://www.shakacode.com/react-on-rails/docs/guides/rendering-extensions")
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
      checker.add_info("📖 Migration guide: https://www.shakacode.com/react-on-rails/docs/guides/upgrading-react-on-rails")
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
      checker.add_info("📖 Full migration guide: https://www.shakacode.com/react-on-rails/docs/guides/upgrading-react-on-rails#upgrading-to-version-16")
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
      checker.add_info("  📖 https://www.shakacode.com/react-on-rails/docs/guides/configuration/")
    end

    def scan_view_files_for_async_pack_tag
      view_patterns = ["app/views/**/*.erb", "app/views/**/*.haml"]
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
      # Note: We need to check the full content first (for multi-line tags) before line-by-line filtering

      # First check if there's any javascript_pack_tag with :async in the full content
      return true unless file_has_async_pack_tag?(content)

      # Now check line-by-line to see if all occurrences are commented
      # For multi-line tags, we check if the starting line is commented
      has_uncommented_async = content.each_line.any? do |line|
        # Skip lines that don't contain javascript_pack_tag
        next unless line.include?("javascript_pack_tag")

        # Skip ERB comments (<%# ... %>)
        next if line.match?(ERB_COMMENT_PATTERN)
        # Skip HAML comments (-# ...)
        next if line.match?(HAML_COMMENT_PATTERN)
        # Skip HTML comments (<!-- ... -->)
        next if line.match?(HTML_COMMENT_PATTERN)

        # If we reach here, this line has an uncommented javascript_pack_tag
        true
      end

      !has_uncommented_async
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
      return unless defined?(Rails.logger) && Rails.logger

      Rails.logger.debug(message)
    end
  end
  # rubocop:enable Metrics/ClassLength
end

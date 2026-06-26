# frozen_string_literal: true

require "json"
require "erb"
require "stringio"
require "tempfile"
require "timeout"
require "yaml"
require_relative "utils"
require_relative "version"
require_relative "config_path_resolver"
require_relative "shakapacker_config_helpers"
require_relative "dev/server_mode"
require_relative "version_syntax_converter"
require_relative "version_synchronizer"
require_relative "system_checker"
require_relative "pro_migration"
require_relative "node_renderer_procfile"

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
    include ShakapackerConfigHelpers

    MESSAGE_COLORS = {
      error: :red,
      warning: :yellow,
      success: :green,
      info: :blue
    }.freeze

    RSPEC_HELPER_FILES = ["spec/rails_helper.rb", "spec/spec_helper.rb"].freeze
    MINITEST_HELPER_FILE = "test/test_helper.rb"
    DEFAULT_BUILD_TEST_COMMAND = 'config.build_test_command = "RAILS_ENV=test bin/shakapacker"'
    SERVER_BUNDLE_SOURCE_EXTENSIONS = %w[.js .jsx .ts .tsx .mjs .cjs].freeze
    CUSTOM_LAUNCHER_INDICATOR_FILES = %w[dev].freeze
    RAILS_SERVER_COMMAND_REGEX = %r{\b(?:(?:bin/)?rails\s+(?:server|s)|puma|unicorn|rackup|passenger\s+start)\b}

    # Deprecated-renderer-cache scan (used by check_deprecated_renderer_cache_task):
    # look for references to the old pre_stage_bundle_for_node_renderer task in
    # common deploy-script locations so users on older Procfile/Dockerfile entries
    # get a migration nudge before the task is removed.
    DEPRECATED_RENDERER_CACHE_TASK = "pre_stage_bundle_for_node_renderer"
    # Fixed allowlist of single-file deploy-script paths. Each entry is a literal
    # path that may host a deploy hook referencing the deprecated task. Directory
    # globs (e.g., per-stage Capistrano files or per-workflow GitHub Actions YAML)
    # live in RENDERER_CACHE_DEPLOY_SCRIPT_GLOBS so they stay bounded.
    RENDERER_CACHE_DEPLOY_SCRIPT_PATHS = [
      "Procfile",
      "Procfile.dev",
      "Procfile.dev-static-assets",
      "Procfile.production",
      "Dockerfile",
      "Dockerfile.production",
      "Dockerfile.staging",
      "Dockerfile.review",
      "docker-compose.yml",
      "docker-compose.yaml",
      "compose.yml",
      "compose.yaml",
      "bin/deploy",
      "bin/release",
      "bin/docker-entrypoint",
      "config/deploy.rb",
      "config/deploy/production.rb",
      "config/deploy/staging.rb",
      ".kamal/deploy.yml",
      "scripts/deploy.sh",
      ".circleci/config.yml",
      ".gitlab-ci.yml",
      "bitbucket-pipelines.yml",
      "Jenkinsfile"
    ].freeze
    # Bounded glob allowlist for deploy manifests that live in a known directory
    # but use per-environment or per-workflow filenames. Each pattern matches
    # only one directory level (no `**`) so the scan never recurses into the
    # project tree, and the expansion is capped by
    # RENDERER_CACHE_DEPLOY_SCRIPT_GLOB_MAX_MATCHES.
    RENDERER_CACHE_DEPLOY_SCRIPT_GLOBS = [
      ".github/workflows/*.yml",
      ".github/workflows/*.yaml",
      "config/deploy/*.rb"
    ].freeze
    # Per-file safety gate to bound IO during the scan, not a meaningful size limit.
    RENDERER_CACHE_DEPLOY_SCRIPT_MAX_BYTES = 1_048_576
    # Defense-in-depth cap on how many files a single glob may contribute.
    # Realistic repos have a handful of workflow / deploy-stage files; far more
    # than this is a sign of an unexpectedly broad pattern, not legitimate config.
    RENDERER_CACHE_DEPLOY_SCRIPT_GLOB_MAX_MATCHES = 100

    # Supported output formats. :text is the human-readable default; :json emits
    # a machine-readable report (see JSON_SCHEMA_VERSION below).
    OUTPUT_FORMATS = %i[text json].freeze

    # Version of the machine-readable doctor report schema (FORMAT=json).
    # Bump ONLY on breaking changes to the shape below. Schema (v1):
    #
    #   {
    #     "schema_version": 1,
    #     "ror_version": "<ReactOnRails::VERSION>",
    #     "status": "pass" | "warn" | "fail",          // worst check status
    #     "checks": [
    #       {
    #         "id": "<stable snake_case id from CHECK_SECTIONS>",
    #         "title": "<human section title>",
    #         "status": "pass" | "warn" | "fail",
    #         "message": "<most severe message content, or null>",
    #         "details": [ { "level": "success|warning|error|info", "content": "..." } ]
    #       }
    #     ],
    #     "summary": { "pass": <count>, "warn": <count>, "fail": <count> }
    #   }
    #
    # No timestamp is included so output is deterministic for a given app state.
    # Exit code semantics match text mode: 1 if any check fails, else 0.
    JSON_SCHEMA_VERSION = 1

    # Doctor check sections. The :id values are part of the stable JSON schema
    # contract (consumed by agents/tooling) — never rename or reuse them; add new
    # sections with new ids instead.
    CHECK_SECTIONS = [
      { id: "environment_prerequisites", title: "Environment Prerequisites", method: :check_environment },
      { id: "react_on_rails_versions", title: "React on Rails Versions", method: :check_react_on_rails_versions },
      { id: "react_on_rails_packages", title: "React on Rails Packages", method: :check_packages },
      { id: "javascript_package_dependencies", title: "JavaScript Package Dependencies",
        method: :check_dependencies },
      { id: "key_configuration_files", title: "Key Configuration Files", method: :check_key_files },
      { id: "configuration_analysis", title: "Configuration Analysis", method: :check_configuration_details },
      { id: "bin_dev_launcher_setup", title: "bin/dev Launcher Setup", method: :check_bin_dev_launcher },
      { id: "rails_integration", title: "Rails Integration", method: :check_rails },
      { id: "bundler_configuration", title: "Bundler Configuration", method: :check_bundler_configuration },
      { id: "testing_setup", title: "Testing Setup", method: :check_testing_setup },
      { id: "development_environment", title: "Development Environment", method: :check_development },
      { id: "react_on_rails_pro_setup", title: "React on Rails Pro Setup", method: :check_pro_setup },
      { id: "react_server_components", title: "React Server Components", method: :check_rsc_setup }
    ].freeze

    def initialize(verbose: false, fix: false, format: :text)
      @verbose = verbose
      @fix = fix
      @format = format.respond_to?(:to_sym) ? format.to_sym : format
      unless OUTPUT_FORMATS.include?(@format)
        raise ArgumentError, "Invalid doctor format #{format.inspect}; expected one of #{OUTPUT_FORMATS.join(', ')}"
      end

      @checker = SystemChecker.new
      @test_output_path_strategy = :unknown
      @rails_environment_loaded = false
    end

    def run_diagnosis
      return run_json_diagnosis if format == :json

      print_header
      run_all_checks
      print_summary
      print_recommendations if should_show_recommendations?

      exit_with_status
    end

    private

    attr_reader :verbose, :fix, :format, :checker

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
      CHECK_SECTIONS.each do |section|
        initial_message_count = checker.messages.length
        send(section[:method])

        # Only print header if messages were added
        next unless checker.messages.length > initial_message_count

        print_section_header(section[:title])
        print_recent_messages(initial_message_count)
        puts
      end
    end

    # JSON output mode: stdout carries ONLY the JSON report (schema documented
    # at JSON_SCHEMA_VERSION); any stray output produced by checks is routed to
    # stderr so the report stays parseable.
    def run_json_diagnosis
      results = nil
      stray_output = capture_stdout { results = collect_check_results }
      $stderr.print(stray_output) unless stray_output.empty?

      puts JSON.pretty_generate(build_json_report(results))
      exit(diagnosis_exit_code)
    end

    def collect_check_results
      CHECK_SECTIONS.map do |section|
        initial_message_count = checker.messages.length
        send(section[:method])

        {
          id: section[:id],
          title: section[:title],
          messages: checker.messages[initial_message_count..]
        }
      end
    end

    # Captures everything written to the stdout file descriptor (fd 1) while the
    # block runs — including direct STDOUT writes, child processes inheriting
    # fd 1, and C extensions — not just Ruby-level $stdout. Reassigning $stdout
    # to a StringIO would miss those, letting stray bytes corrupt the JSON report.
    #
    # NOT thread-safe: STDOUT.reopen redirects fd 1 process-wide, so any
    # concurrent thread writing to stdout is captured too. Doctor runs only as
    # a single-threaded rake task today; revisit before using in threaded code.
    # rubocop:disable Style/GlobalStdStream
    def capture_stdout
      captured_file = Tempfile.new("react_on_rails_doctor_stdout")
      original_stdout = $stdout
      original_fd = STDOUT.dup
      STDOUT.flush
      STDOUT.reopen(captured_file.path, "w")
      $stdout = STDOUT
      yield
      STDOUT.flush
      File.read(captured_file.path)
    ensure
      begin
        STDOUT.flush
      rescue IOError, SystemCallError
        nil
      end
      if original_fd
        begin
          STDOUT.reopen(original_fd)
        ensure
          original_fd.close
        end
      end
      $stdout = original_stdout if original_stdout
      captured_file&.close!
    end
    # rubocop:enable Style/GlobalStdStream

    def build_json_report(results)
      checks = results.map { |result| build_check_entry(result) }
      statuses = checks.map { |check| check[:status] }

      {
        schema_version: JSON_SCHEMA_VERSION,
        ror_version: ReactOnRails::VERSION,
        status: overall_status(statuses),
        checks:,
        summary: {
          pass: statuses.count("pass"),
          warn: statuses.count("warn"),
          fail: statuses.count("fail")
        }
      }
    end

    def build_check_entry(result)
      messages = result[:messages]
      status = check_status(messages)

      {
        id: result[:id],
        title: result[:title],
        status:,
        message: primary_message(messages, status),
        details: messages.map { |message| { level: message[:type].to_s, content: message[:content] } }
      }
    end

    def check_status(messages)
      if messages.any? { |message| message[:type] == :error }
        "fail"
      elsif messages.any? { |message| message[:type] == :warning }
        "warn"
      else
        "pass"
      end
    end

    def overall_status(statuses)
      if statuses.include?("fail")
        "fail"
      elsif statuses.include?("warn")
        "warn"
      else
        "pass"
      end
    end

    def primary_message(messages, status)
      severity = { "fail" => :error, "warn" => :warning }[status]
      return nil unless severity

      message = messages.find { |msg| msg[:type] == severity }
      message && message[:content]
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
      # Auto-fix first so subsequent checks reflect the repaired state and
      # don't leave stale errors that cause exit(1) despite a successful fix.
      auto_fix_versions if fix

      checker.check_react_on_rails_packages
      check_pro_package_consistency
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

    def check_bundler_configuration
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
      return unless check_bin_dev_launcher_setup

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
      if server_bundle_filename.to_s.strip.empty?
        checker.add_info("ℹ️  server_bundle_js_file is blank (SSR disabled), skipping SSR bundle existence check")
        return
      end

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
      default_mode = default_dev_server_mode
      descriptions = procfile_descriptions
      procfiles = {
        "Procfile.dev" => {
          description: default_procfile_description(default_mode),
          required_for: "bin/dev (default mode)",
          should_contain: ["shakapacker-dev-server", "rails server"]
        },
        "Procfile.dev-static-assets" => {
          description: descriptions[:static],
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
          procfile_description = config[:description]
          checker.add_warning(
            "  ⚠️  #{procfile_description} (Procfile.dev) requires shakapacker-dev-server"
          )
        elsif filename == "Procfile.dev-static-assets" && !content.include?("shakapacker")
          checker.add_warning("  ⚠️  Missing shakapacker for static asset compilation")
        end
      else
        checker.add_info("ℹ️  #{filename} not found (needed for #{config[:required_for]})")
      end
    end

    def procfile_descriptions
      {
        hmr: "#{development_reload_mode_label} development with #{dev_server_label}",
        static: "Static development with #{static_watch_label}"
      }
    end

    def default_procfile_description(default_mode)
      bundler_aware_dev_server_text(Dev::ServerMode.text(default_mode, :procfile_description))
    end

    def bundler_aware_dev_server_text(text)
      return text if active_assets_bundler == "webpack"

      text.gsub("webpack-dev-server", dev_server_label)
    end

    def check_bin_dev_script
      bin_dev_path = "bin/dev"
      if File.exist?(bin_dev_path)
        checker.add_success("✅ bin/dev script exists")
        check_bin_dev_content(bin_dev_path)
      else
        checker.add_warning(<<~MSG.strip)
          ⚠️  bin/dev script missing
          This script provides an enhanced development workflow with development-server, static, and production modes.
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
          puts "  - Provides development-server, static, and production-like asset modes"
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
        puts "• Start development with #{Dev::ServerMode.text(default_dev_server_mode, :next_step_label)}: " \
             "#{Rainbow('./bin/dev').cyan}"
        puts "• Try static mode: #{Rainbow('./bin/dev static').cyan}"
        puts "• Test production assets: #{Rainbow('./bin/dev prod').cyan}"
        puts "• See all options: #{Rainbow('./bin/dev help').cyan}"
      elsif File.exist?("Procfile.dev")
        puts "• Start development with: #{Rainbow('./bin/dev').cyan} (or foreman start -f Procfile.dev)"
      else
        puts "• Start Rails server: bin/rails server"
        puts "• Start #{dev_server_label}: bin/shakapacker-dev-server (in separate terminal)"
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

    def static_watch_label
      active_assets_bundler == "webpack" ? "webpack --watch" : "#{active_assets_bundler} watch"
    end
    # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

    # Memoized per Doctor instance (a fresh Doctor runs per `doctor` invocation),
    # so a single diagnosis reads and parses config/shakapacker.yml at most once
    # even though several checks consult it. The base implementation lives in
    # ShakapackerConfigHelpers. ServerManager intentionally does not memoize its
    # copy because its helpers live on `class << self` and would leak across specs.
    def parsed_shakapacker_config
      return @parsed_shakapacker_config if defined?(@parsed_shakapacker_config)

      @parsed_shakapacker_config = super
    end

    def print_test_workflow_next_steps
      case @test_output_path_strategy
      when :shared
        puts "• Shared test/dev output path detected: use static workflow only"
        puts "  - Start app with: ./bin/dev static"
        puts "  - Avoid ./bin/dev (#{Dev::ServerMode.text(default_dev_server_mode, :next_step_label)}) " \
             "with shared output paths"
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
      package_json_path = package_json_path_for("react-on-rails npm package version")
      return unless package_json_path

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
        check_gem_wildcard_for(content, "react_on_rails")
        check_gem_wildcard_for(content, "react_on_rails_pro") if ReactOnRails::Utils.react_on_rails_pro?
      rescue StandardError
        # Ignore errors reading Gemfile
      end
    end

    def check_gem_wildcard_for(gemfile_content, gem_name)
      lines = gemfile_content.lines
      line_index = lines.index { |line| line.match(/^\s*gem\s+['"]#{gem_name}['"]/) }
      return unless line_index

      react_line = build_gem_declaration_line(lines, line_index)

      # Skip path/git/github gems — these are development configurations where version checks don't apply
      return if react_line.match?(/\b(?:path|git|github):\s/)

      version_match = react_line.match(/gem\s+['"]#{gem_name}['"]\s*,\s*['"]([^'"]+)['"]/) ||
                      react_line.match(/gem\s+['"]#{gem_name}['"][^#\n]*\bversion:\s*['"]([^'"]+)['"]/)
      return report_missing_gem_version(gem_name) unless version_match

      exact = begin
        Gem::Requirement.new(version_match[1]).exact?
      rescue Gem::Requirement::BadRequirementError
        false
      end

      if exact
        checker.add_success("✅ Gemfile uses exact version for #{gem_name}")
      else
        report_non_exact_gem_version(gem_name)
      end
    end

    def build_gem_declaration_line(lines, line_index)
      declaration = lines[line_index]
      look_ahead = line_index + 1

      # Keep joining while the previous segment ends with a comma; skip blank/comment-only continuation lines.
      while declaration.sub(/#[^\n]*\z/, "").rstrip.end_with?(",") && lines[look_ahead]
        next_line = lines[look_ahead]
        look_ahead += 1
        next if next_line.strip.empty? || next_line.strip.start_with?("#")

        declaration = "#{declaration.chomp.sub(/#[^\n]*\z/, '').rstrip} #{next_line.strip}"
      end

      declaration
    end

    def report_missing_gem_version(gem_name)
      version = gem_expected_version(gem_name)
      checker.add_error(<<~MSG.strip)
        🚫 Gemfile specifies no version for #{gem_name}.

        React on Rails requires exact version pinning. Without a version constraint,
        bundler may install any version and it can drift from the npm package.

        Fix: Use an exact version in your Gemfile:
          gem '#{gem_name}', '#{version}'
      MSG
    end

    def report_non_exact_gem_version(gem_name)
      version = gem_expected_version(gem_name)
      checker.add_error(<<~MSG.strip)
        🚫 Gemfile uses a non-exact version constraint for #{gem_name}.

        React on Rails requires exact version matching between the gem and npm package.
        Non-exact constraints can cause the gem and npm package to drift apart.

        Fix: Use an exact version in your Gemfile:
          gem '#{gem_name}', '#{version}'
      MSG
    end

    def gem_expected_version(gem_name)
      if gem_name == "react_on_rails_pro"
        ReactOnRails::Utils.react_on_rails_pro_version
      else
        ReactOnRails::VERSION
      end
    end

    def check_npm_wildcards
      package_json_path = package_json_path_for("npm package version constraints")
      return unless package_json_path

      begin
        package_json = JSON.parse(File.read(package_json_path))
        packages = ["react-on-rails"]
        if ReactOnRails::Utils.react_on_rails_pro?
          packages << "react-on-rails-pro"
          packages << "react-on-rails-pro-node-renderer"
        end

        packages.each do |package_name|
          ReactOnRails::VersionSynchronizer::PACKAGE_SECTIONS.each do |section|
            deps = package_json[section] || {}
            next unless deps.key?(package_name)

            check_npm_wildcard_for(deps, package_name)
            break # only report once per package (avoid duplicates if listed in multiple sections)
          end
        end
      rescue JSON::ParserError
        # Ignore JSON parsing errors
      rescue StandardError
        # Ignore other errors
      end
    end

    def check_npm_wildcard_for(all_deps, package_name)
      npm_version = all_deps[package_name]
      return unless npm_version

      # Skip workspace/local-link specs
      return if npm_version.match?(/\A(?:workspace:|file:|link:)/)

      # Handle npm alias syntax (e.g., npm:@scope/pkg@^16.5.0) — check the embedded version
      if npm_version.start_with?(ReactOnRails::VersionSynchronizer::NPM_ALIAS_PREFIX)
        return check_npm_alias_version(npm_version, package_name)
      end

      if ReactOnRails::VersionSynchronizer::EXACT_VERSION_REGEX.match?(npm_version)
        checker.add_success("✅ package.json uses exact version for #{package_name}")
      else
        install_cmd = install_exact_command_for(package_name)
        checker.add_error(<<~MSG.strip)
          🚫 package.json uses a non-exact version for #{package_name}: #{npm_version}

          React on Rails requires exact version matching between the gem and npm package.
          Non-exact constraints (~ ^ >= * ranges) will cause a runtime error on app startup.

          Fix: #{install_cmd}
          Or run: bundle exec rake react_on_rails:sync_versions WRITE=true
        MSG
      end
    end

    def check_npm_alias_version(npm_version, package_name)
      expected_version = expected_npm_version_for(package_name)
      install_cmd = install_exact_command_for(package_name)
      at_index = npm_version.rindex("@")
      unless at_index && at_index > ReactOnRails::VersionSynchronizer::NPM_ALIAS_PREFIX.length
        checker.add_error(<<~MSG.strip)
          🚫 package.json uses an npm alias without a parseable version for #{package_name}: #{npm_version}

          React on Rails requires exact version matching between the gem and npm package.
          npm alias specs must include an exact trailing version.

          Fix: #{install_cmd}
          Run: bundle exec rake react_on_rails:sync_versions WRITE=true
        MSG
        return
      end

      alias_version = npm_version[(at_index + 1)..]
      exact_alias = ReactOnRails::VersionSynchronizer::EXACT_VERSION_REGEX.match?(alias_version)

      if exact_alias && alias_version == expected_version
        checker.add_success("✅ package.json uses exact version for #{package_name}")
      elsif exact_alias
        checker.add_error(<<~MSG.strip)
          🚫 package.json npm alias version mismatch for #{package_name}: #{npm_version}

          React on Rails requires exact version matching between the gem and npm package.
          Expected exact version: #{expected_version}

          Fix: #{install_cmd}
          Run: bundle exec rake react_on_rails:sync_versions WRITE=true
        MSG
      else
        checker.add_error(<<~MSG.strip)
          🚫 package.json uses a non-exact version in npm alias for #{package_name}: #{npm_version}

          React on Rails requires exact version matching between the gem and npm package.
          Non-exact constraints (~ ^ >= * ranges) will cause a runtime error on app startup.

          Fix: #{install_cmd}
          Run: bundle exec rake react_on_rails:sync_versions WRITE=true
        MSG
      end
    end

    def expected_npm_version_for(package_name)
      gem_version = if %w[react-on-rails-pro react-on-rails-pro-node-renderer].include?(package_name)
                      ReactOnRails::Utils.react_on_rails_pro_version
                    else
                      ReactOnRails::VERSION
                    end
      ReactOnRails::VersionSyntaxConverter.new.rubygem_to_npm(gem_version)
    end

    def install_exact_command_for(package_name)
      ReactOnRails::Utils.package_manager_install_exact_command(package_name, expected_npm_version_for(package_name))
    end

    def auto_fix_versions
      package_json_path = package_json_path_for("package version auto-sync")
      return unless package_json_path

      synchronizer = ReactOnRails::VersionSynchronizer.new(package_json_path:, io: StringIO.new)
      result = synchronizer.sync(write: true)

      report_sync_changes(result)
      report_skipped_specs(result)
      if result.changes.any?
        checker.add_info("  ℹ️  FIX=true only updates package.json; update Gemfile constraints manually if needed.")
      end
    rescue StandardError => e
      checker.add_warning("  ⚠️  FIX=true: Could not auto-sync versions: #{e.message}")
    end

    def report_sync_changes(result)
      if result.changes.any?
        checker.add_success("  ✅ FIX=true: Synced package.json versions (#{result.changes.length} update(s))")
        result.changes.each do |change|
          checker.add_info("    #{change[:section]}.#{change[:package]}: #{change[:from]} -> #{change[:to]}")
        end
        checker.add_info("  ℹ️  Run your package manager install command to update the lockfile.")
      elsif result.unsupported_specs.any? || result.missing_source_specs.any?
        checker.add_warning("  ⚠️  FIX=true: Some package.json specs could not be auto-synced")
      else
        checker.add_info("  ℹ️  FIX=true: No package.json version changes needed")
      end
    end

    def report_skipped_specs(result)
      result.unsupported_specs.each do |spec|
        checker.add_warning(
          "  ⚠️  FIX=true: Skipped unsupported spec " \
          "#{spec[:section]}.#{spec[:package]}: #{spec[:version]}"
        )
      end
      result.missing_source_specs.each do |spec|
        checker.add_warning(
          "  ⚠️  FIX=true: Skipped #{spec[:section]}.#{spec[:package]} " \
          "(#{spec[:source]} gem not loaded)"
        )
      end
    end

    def check_pro_package_consistency
      package_json_path = package_json_path_for("Pro package consistency")
      return unless package_json_path

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
        checker.add_success("✅ Bundler configuration: #{webpack_config_path}")
      else
        checker.add_warning("⚠️  Missing bundler configuration: webpack/rspack config file not found")
        checker.add_info(
          "ℹ️  Checked default config locations and Shakapacker assets_bundler_config_path, if available."
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

    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def check_server_rendering_engine
      return unless defined?(ReactOnRails)

      checker.add_info("\n🖥️  Server Rendering Engine:")

      begin
        pro_renderer = resolved_pro_server_renderer
        uses_node_renderer = pro_renderer == "NodeRenderer"

        if uses_node_renderer
          checker.add_info("  Pro uses NodeRenderer for server rendering")
          if defined?(ExecJS) && ExecJS.runtime
            checker.add_info("  ExecJS available as fallback: #{ExecJS.runtime.name}")
          elsif pro_execjs_fallback_enabled?
            checker.add_warning("  ⚠️  ExecJS fallback is enabled but ExecJS is not available")
            checker.add_info("  💡 Install mini_racer or set renderer_use_fallback_exec_js = false")
          else
            checker.add_info("  ℹ️  ExecJS fallback is disabled (renderer_use_fallback_exec_js = false)")
          end
        elsif defined?(ExecJS)
          runtime_name = ExecJS.runtime.name if ExecJS.runtime
          if runtime_name
            checker.add_info("  ExecJS Runtime: #{runtime_name}")

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
    # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

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
      runtime_config = react_on_rails_runtime_configuration
      initializer_exists = File.exist?(config_path)

      unless runtime_config || initializer_exists
        checker.add_warning("⚠️  React on Rails configuration file not found: #{config_path}")
        checker.add_info("💡 Run 'rails generate react_on_rails:install' to create configuration file")
        return
      end

      if !initializer_exists && runtime_config
        checker.add_info("ℹ️  No config/initializers/react_on_rails.rb found (using runtime configuration)")
      end

      begin
        content = initializer_exists ? File.read(config_path) : ""

        checker.add_info("📋 React on Rails Configuration:")
        checker.add_info("📍 Documentation: https://reactonrails.com/docs/configuration/")
        if runtime_config
          checker.add_info("ℹ️  Using loaded runtime configuration values")
        else
          checker.add_info("ℹ️  Using initializer parsing fallback (Rails environment unavailable)")
        end

        # Analyze configuration settings
        analyze_server_rendering_config(content, runtime_config)
        analyze_performance_config(content, runtime_config)
        analyze_development_config(content, runtime_config)
        analyze_i18n_config(content, runtime_config)
        analyze_component_loading_config(content, runtime_config)
        analyze_custom_extensions(content, runtime_config)
      rescue StandardError => e
        checker.add_warning("⚠️  Unable to read react_on_rails.rb: #{e.message}")
      end
    end

    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
    def analyze_server_rendering_config(content, runtime_config = nil)
      checker.add_info("\n🖥️  Server Rendering:")

      if runtime_config
        raw_server_bundle_value = runtime_config.server_bundle_js_file
        server_bundle_value =
          if raw_server_bundle_value.is_a?(String)
            raw_server_bundle_value.strip
          else
            raw_server_bundle_value
          end
        if server_bundle_value.present?
          checker.add_info("  server_bundle_js_file: #{server_bundle_value}")
        elsif server_bundle_value.nil?
          fallback_server_bundle = server_bundle_filename
          checker.add_info("  server_bundle_js_file: #{fallback_server_bundle} (initializer/default)")
        else
          checker.add_info("  server_bundle_js_file: \"\" (disabled)")
        end
      else
        # Server bundle file
        server_bundle_match = content.match(/config\.server_bundle_js_file\s*=\s*["']([^"']+)["']/)
        if server_bundle_match
          checker.add_info("  server_bundle_js_file: #{server_bundle_match[1]}")
        else
          checker.add_info('  server_bundle_js_file: "" (default, SSR disabled)')
        end
      end

      # Server bundle output path
      default_path = ReactOnRails::DEFAULT_SERVER_BUNDLE_OUTPUT_PATH
      rails_bundle_path =
        if runtime_config
          runtime_config.server_bundle_output_path || default_path
        else
          server_bundle_path_match = content.match(/config\.server_bundle_output_path\s*=\s*["']([^"']+)["']/)
          server_bundle_path_match ? server_bundle_path_match[1] : default_path
        end
      checker.add_info("  server_bundle_output_path: #{rails_bundle_path}")

      # Enforce private server bundles
      if runtime_config
        checker.add_info("  enforce_private_server_bundles: true") if runtime_config.enforce_private_server_bundles
      else
        enforce_private_match = content.match(/config\.enforce_private_server_bundles\s*=\s*([^\s\n,]+)/)
        checker.add_info("  enforce_private_server_bundles: #{enforce_private_match[1]}") if enforce_private_match
      end

      # Check Shakapacker integration and provide recommendations
      check_shakapacker_private_output_path(rails_bundle_path)

      # RSC bundle file (Pro feature). Base runtime config does not expose this setting.
      rsc_bundle_value =
        if runtime_config && defined?(ReactOnRailsPro)
          ReactOnRailsPro.configuration.rsc_bundle_js_file
        else
          rsc_bundle_match = content.match(/config\.rsc_bundle_js_file\s*=\s*["']([^"']+)["']/)
          rsc_bundle_match ? rsc_bundle_match[1] : nil
        end
      if rsc_bundle_value.present?
        checker.add_info("  rsc_bundle_js_file: #{rsc_bundle_value} (React Server Components - Pro)")
      end

      # Prerender setting
      prerender_value =
        if runtime_config
          runtime_config.prerender
        else
          prerender_match = content.match(/config\.prerender\s*=\s*([^\s\n,]+)/)
          prerender_match ? prerender_match[1] : "false (default)"
        end
      checker.add_info("  prerender: #{prerender_value}")

      # Server renderer pool settings
      if runtime_config
        # Default is 1; only report explicit non-default override.
        checker.add_info("  server_renderer_pool_size: #{runtime_config.server_renderer_pool_size}") \
          if runtime_config.server_renderer_pool_size != ReactOnRails::DEFAULT_SERVER_RENDERER_POOL_SIZE
      else
        pool_size_match = content.match(/config\.server_renderer_pool_size\s*=\s*([^\s\n,]+)/)
        checker.add_info("  server_renderer_pool_size: #{pool_size_match[1]}") if pool_size_match
      end

      if runtime_config
        # Default is 20 seconds; only report explicit non-default override.
        checker.add_info("  server_renderer_timeout: #{runtime_config.server_renderer_timeout} seconds") \
          if runtime_config.server_renderer_timeout != ReactOnRails::DEFAULT_SERVER_RENDERER_TIMEOUT_SECONDS
      else
        timeout_match = content.match(/config\.server_renderer_timeout\s*=\s*([^\s\n,]+)/)
        checker.add_info("  server_renderer_timeout: #{timeout_match[1]} seconds") if timeout_match
      end

      # Error handling
      if runtime_config
        checker.add_info("  raise_on_prerender_error: #{runtime_config.raise_on_prerender_error}") \
          if runtime_config.raise_on_prerender_error != Rails.env.development?
      else
        raise_on_error_match = content.match(/config\.raise_on_prerender_error\s*=\s*([^\s\n,]+)/)
        checker.add_info("  raise_on_prerender_error: #{raise_on_error_match[1]}") if raise_on_error_match
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def analyze_performance_config(content, runtime_config = nil)
      checker.add_info("\n⚡ Performance & Loading:")

      # Component loading strategy
      strategy =
        if runtime_config
          runtime_config.generated_component_packs_loading_strategy&.to_s
        else
          loading_strategy_match =
            content.match(/config\.generated_component_packs_loading_strategy\s*=\s*:([^\s\n,]+)/)
          loading_strategy_match&.[](1)
        end
      if strategy
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
      if runtime_config
        checker.add_info("  auto_load_bundle: true") if runtime_config.auto_load_bundle
      else
        auto_load_match = content.match(/config\.auto_load_bundle\s*=\s*([^\s\n,]+)/)
        checker.add_info("  auto_load_bundle: #{auto_load_match[1]}") if auto_load_match
      end

      # Component registry timeout
      if runtime_config
        # Default is 5000 ms; only report explicit non-default override.
        checker.add_info("  component_registry_timeout: #{runtime_config.component_registry_timeout}ms") \
          if runtime_config.component_registry_timeout != ReactOnRails::DEFAULT_COMPONENT_REGISTRY_TIMEOUT
      else
        timeout_match = content.match(/config\.component_registry_timeout\s*=\s*([^\s\n,]+)/)
        checker.add_info("  component_registry_timeout: #{timeout_match[1]}ms") if timeout_match
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
    def analyze_development_config(content, runtime_config = nil)
      checker.add_info("\n🔧 Development & Debugging:")

      if runtime_config
        # development_mode/trace default to Rails.env.development?, so only
        # surface explicit runtime divergence from that environment-driven
        # default.
        checker.add_info("  development_mode: #{runtime_config.development_mode}") \
          if runtime_config.development_mode != Rails.env.development?
        checker.add_info("  trace: #{runtime_config.trace}") \
          if runtime_config.trace != Rails.env.development?
        # logging_on_server/replay_console default to true in all environments,
        # so any non-truthy runtime value is worth surfacing.
        unless runtime_config.logging_on_server
          checker.add_info("  logging_on_server: #{runtime_config.logging_on_server.inspect}")
        end
        unless runtime_config.replay_console
          checker.add_info("  replay_console: #{runtime_config.replay_console.inspect}")
        end
        if runtime_config.build_test_command.present?
          checker.add_info("  build_test_command: #{runtime_config.build_test_command}")
        end
        if runtime_config.build_production_command.present?
          checker.add_info("  build_production_command: #{runtime_config.build_production_command}")
        end
      else
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
        checker.add_info("  build_production_command: #{build_prod_match[1]}") if build_prod_match
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def analyze_i18n_config(content, runtime_config = nil)
      i18n_configs = []

      if runtime_config
        i18n_configs << "i18n_dir: #{runtime_config.i18n_dir}" if runtime_config.i18n_dir.present?
        i18n_configs << "i18n_yml_dir: #{runtime_config.i18n_yml_dir}" if runtime_config.i18n_yml_dir.present?
        if runtime_config.i18n_output_format.present?
          i18n_configs << "i18n_output_format: #{runtime_config.i18n_output_format}"
        end
      else
        i18n_dir_match = content.match(/config\.i18n_dir\s*=\s*["']([^"']+)["']/)
        i18n_configs << "i18n_dir: #{i18n_dir_match[1]}" if i18n_dir_match

        i18n_yml_dir_match = content.match(/config\.i18n_yml_dir\s*=\s*["']([^"']+)["']/)
        i18n_configs << "i18n_yml_dir: #{i18n_yml_dir_match[1]}" if i18n_yml_dir_match

        i18n_format_match = content.match(/config\.i18n_output_format\s*=\s*["']([^"']+)["']/)
        i18n_configs << "i18n_output_format: #{i18n_format_match[1]}" if i18n_format_match
      end

      return unless i18n_configs.any?

      checker.add_info("\n🌍 Internationalization:")
      i18n_configs.each { |config| checker.add_info("  #{config}") }
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def analyze_component_loading_config(content, runtime_config = nil)
      component_configs = []
      filesystem_registry_enabled = false

      if runtime_config
        if runtime_config.components_subdirectory.present?
          component_configs << "components_subdirectory: #{runtime_config.components_subdirectory}"
          filesystem_registry_enabled = true
        end
        # Default is false; only report explicit non-default override.
        if runtime_config.same_bundle_for_client_and_server
          component_configs << "same_bundle_for_client_and_server: #{runtime_config.same_bundle_for_client_and_server}"
        end
        # Default is true; only report explicit non-default override.
        component_configs << "random_dom_id: #{runtime_config.random_dom_id}" if runtime_config.random_dom_id == false
      else
        components_subdir_match = content.match(/config\.components_subdirectory\s*=\s*["']([^"']+)["']/)
        if components_subdir_match
          component_configs << "components_subdirectory: #{components_subdir_match[1]}"
          filesystem_registry_enabled = true
        end

        same_bundle_match = content.match(/config\.same_bundle_for_client_and_server\s*=\s*([^\s\n,]+)/)
        component_configs << "same_bundle_for_client_and_server: #{same_bundle_match[1]}" if same_bundle_match

        random_dom_match = content.match(/config\.random_dom_id\s*=\s*([^\s\n,]+)/)
        component_configs << "random_dom_id: #{random_dom_match[1]}" if random_dom_match
      end

      return unless component_configs.any?

      checker.add_info("\n📦 Component Loading:")
      component_configs.each { |config| checker.add_info("  #{config}") }
      checker.add_info("    ℹ️  File-system based component registry enabled") if filesystem_registry_enabled
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def analyze_custom_extensions(content, runtime_config = nil)
      extension_messages = []
      has_rendering_extension = false

      if runtime_config
        has_rendering_extension = runtime_config.rendering_extension.present?
        if runtime_config.rendering_props_extension.present?
          extension_messages << "  rendering_props_extension: Custom props logic detected"
        end
        if runtime_config.server_render_method.present?
          extension_messages << "  server_render_method: #{runtime_config.server_render_method}"
        end
      else
        has_rendering_extension = /config\.rendering_extension\s*=\s*([^\s\n,]+)/.match?(content)
        if /config\.rendering_props_extension\s*=\s*([^\s\n,]+)/.match?(content)
          extension_messages << "  rendering_props_extension: Custom props logic detected"
        end

        server_method_match = content.match(/config\.server_render_method\s*=\s*["']([^"']+)["']/)
        extension_messages << "  server_render_method: #{server_method_match[1]}" if server_method_match
      end

      return unless has_rendering_extension || extension_messages.any?

      checker.add_info("\n🔌 Custom Extensions:")
      if has_rendering_extension
        checker.add_info("  rendering_extension: Custom rendering logic detected")
        checker.add_info("    ℹ️  See: https://reactonrails.com/docs/configuration/#rendering_extension")
      end
      extension_messages.each { |msg| checker.add_info(msg) }
    end
    # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

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
      checker.add_info("📖 Migration guide: https://reactonrails.com/docs/upgrading/upgrading-react-on-rails")
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
      checker.add_info("📖 Full migration guide: https://reactonrails.com/docs/upgrading/upgrading-react-on-rails#upgrading-to-version-16")
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

    def check_v14_breaking_changes
      checker.add_info("\n📋 React on Rails v14+ Notes:")
      checker.add_info("  • Enhanced React Server Components (RSC) support available in Pro")
      checker.add_info("  • Improved component loading strategies")
      checker.add_info("  • Modern React patterns recommended")
    end

    # Returns true if bin/dev exists, false otherwise.
    # Used by check_bin_dev_launcher to decide whether to check Procfiles.
    def check_bin_dev_launcher_setup
      bin_dev_path = "bin/dev"

      unless File.exist?(bin_dev_path)
        checker.add_warning("  ⚠️  Official React on Rails bin/dev launcher not found")
        custom_launchers = detected_custom_launcher_paths
        if custom_launchers.any?
          checker.add_info(
            "    ℹ️  Custom launcher detected (#{custom_launchers.join(', ')}). " \
            "This is OK if your project intentionally manages its own dev workflow."
          )
          checker.add_info("    💡 To use the official launcher instead, run: rails generate react_on_rails:install")
        else
          checker.add_info("    💡 Generate the official launcher with: rails generate react_on_rails:install")
        end
        return false
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

      true
    end

    def check_launcher_procfiles
      # Keep these launcher filenames aligned with NodeRendererProcfile::DEFAULT_COMMANDS.
      default_mode = default_dev_server_mode
      procfiles = {
        "Procfile.dev" => Dev::ServerMode.text(default_mode, :launcher_description),
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

      check_node_renderer_launcher_procfiles(NodeRendererProcfile::DEFAULT_COMMANDS.keys)
    end

    def check_node_renderer_launcher_procfiles(procfiles)
      return unless resolved_pro_server_renderer == "NodeRenderer"

      procfiles.each do |filename|
        next unless File.exist?(filename)

        content = File.read(filename)
        next unless procfile_serves_rails_pages?(content)
        next if procfile_starts_node_renderer_on_renderer_port?(content)

        checker.add_warning(<<~MSG.strip)
          ⚠️  #{filename} can serve SSR pages but does not start the Node Renderer on RENDERER_PORT.

          Add a process such as:
            #{node_renderer_procfile_command(filename)}
        MSG
      end
    end

    def procfile_serves_rails_pages?(content)
      active_procfile_lines(content).any? { |line| line.match?(RAILS_SERVER_COMMAND_REGEX) }
    end

    def procfile_starts_node_renderer_on_renderer_port?(content)
      active_procfile_lines(content).any? do |line|
        line.match?(NodeRendererProcfile::PROCESS_WITH_RENDERER_PORT_REGEX)
      end
    end

    def active_procfile_lines(content)
      content.each_line.grep_v(/^\s*#/).map { |line| line.sub(/#.*/, "") }
    end

    def node_renderer_procfile_command(filename)
      # When the app still has only the legacy client/node-renderer.js (Pro
      # setup intentionally skips Procfile rewrites in that case), suggesting
      # renderer/node-renderer.js would point at a non-existent file. Mirror
      # the legacy path back so the doctor's hint stays runnable.
      if legacy_node_renderer_only?
        NodeRendererProcfile.command_for(
          filename,
          renderer_script: NodeRendererProcfile::LEGACY_RENDERER_SCRIPT_PATH
        )
      else
        NodeRendererProcfile.command_for(filename)
      end
    end

    def legacy_node_renderer_only?
      File.exist?(NodeRendererProcfile::LEGACY_RENDERER_SCRIPT_PATH) &&
        !File.exist?(NodeRendererProcfile::NEW_RENDERER_SCRIPT_PATH)
    end

    def detected_custom_launcher_paths
      CUSTOM_LAUNCHER_INDICATOR_FILES.filter_map do |path|
        next unless File.file?(path)

        path == "dev" ? "./dev" : path
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

      bundle_path = File.join(source_path, source_entry_path, bundle_filename)
      resolve_server_bundle_source_path(bundle_path)
    rescue LoadError, StandardError
      # Handle missing Shakapacker gem or other configuration errors
      bundle_filename = server_bundle_filename
      resolve_server_bundle_source_path("app/javascript/packs/#{bundle_filename}")
    end

    def server_bundle_filename
      runtime_config = react_on_rails_runtime_configuration
      if runtime_config
        configured_value = runtime_config.server_bundle_js_file
        # A blank runtime value intentionally disables SSR bundle checks; only nil falls back.
        return configured_value unless configured_value.nil?
      end

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

    def resolve_server_bundle_source_path(bundle_path)
      return bundle_path if File.exist?(bundle_path)

      base_path = bundle_path.sub(%r{\.[^./]+\z}, "")

      candidate_extensions = server_bundle_source_extensions_for(bundle_path)
      candidate_extensions.each do |extension|
        candidate_path = "#{base_path}#{extension}"
        return candidate_path if File.exist?(candidate_path)
      end

      bundle_path
    end

    def server_bundle_source_extensions_for(bundle_path)
      extension = File.extname(bundle_path)
      return SERVER_BUNDLE_SOURCE_EXTENSIONS if extension.empty?

      SERVER_BUNDLE_SOURCE_EXTENSIONS.reject { |candidate_extension| candidate_extension == extension }
    end

    def exit_with_status
      if checker.errors?
        puts Rainbow("❌ Doctor found critical issues. Please address errors above.").red.bold
      elsif checker.warnings?
        puts Rainbow("⚠️  Doctor found some issues. Consider addressing warnings above.").yellow
      else
        puts Rainbow("🎉 All checks passed! Your React on Rails setup is healthy.").green.bold
      end

      exit(diagnosis_exit_code)
    end

    def diagnosis_exit_code
      checker.errors? ? 1 : 0
    end

    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def check_server_bundle_prerender_consistency
      config_path = "config/initializers/react_on_rails.rb"
      runtime_config = react_on_rails_runtime_configuration
      return unless runtime_config || File.exist?(config_path)

      checker.add_info("\n🔍 Server Rendering Consistency:")

      begin
        if runtime_config
          server_bundle_value = runtime_config.server_bundle_js_file
          server_bundle_set =
            if server_bundle_value.nil?
              server_bundle_filename.to_s.strip.present?
            else
              server_bundle_value.present?
            end
          prerender_set = runtime_config.prerender
        else
          content = File.read(config_path)

          # Check for server bundle configuration
          server_bundle_match = content.match(/config\.server_bundle_js_file\s*=\s*["']([^"']+)["']/)
          server_bundle_set = server_bundle_match && server_bundle_match[1].present?

          # Check for global prerender setting
          prerender_match = content.match(/config\.prerender\s*=\s*(true)/)
          prerender_set = prerender_match
        end

        # Check if prerender is used in views
        uses_prerender = uses_prerender_in_views?

        # Analyze the configuration
        if (prerender_set || uses_prerender) && !server_bundle_set
          checker.add_warning("  ⚠️  Server rendering is enabled but server_bundle_js_file is not configured")
          checker.add_info("  💡 Set config.server_bundle_js_file = 'server-bundle.js' to enable SSR")
          checker.add_info("  💡 See: https://reactonrails.com/docs/core-concepts/react-server-rendering/")
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
      view_files = Dir.glob("app/views/**/*.{erb,haml,slim}")
      view_files.any? do |file|
        next unless File.exist?(file)

        content = File.read(file)
        # Match explicit prerender: true OR Pro streaming helpers that implicitly prerender
        content.match?(/prerender:\s*true/) ||
          content.match?(/stream_react_component|cached_stream_react_component|rsc_payload_react_component/)
      end
    rescue StandardError
      false
    end

    def pro_initializer_has_node_renderer?
      config_path = "config/initializers/react_on_rails_pro.rb"
      return false unless File.exist?(config_path)

      File.read(config_path).match?(/server_renderer\s*=\s*["']NodeRenderer["']/)
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

    # Resolves SHAKAPACKER_CONFIG the same way ReactOnRails::Engine and Dev::ServerManager do, so
    # doctor inspects the same config file as Rails boot even when invoked from a directory other
    # than the Rails root. Without this, a relative SHAKAPACKER_CONFIG would fail to resolve and
    # dev-server mode detection would silently fall back to HMR labels. Falls back to Dir.pwd when
    # Rails isn't booted (e.g. in unit specs).
    def default_dev_server_mode
      @default_dev_server_mode ||= Dev::ServerMode.detect(shakapacker_config_path)
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
        checker.add_info(
          "  💡 #{Dev::ServerMode.text(default_dev_server_mode, :shared_output_warning)} because manifests can collide"
        )
        add_shared_output_path_procfile_guidance
      else
        @test_output_path_strategy = :separate
        checker.add_success("  ✅ test and development use separate public_output_path values (recommended)")
        checker.add_info("  💡 Separate output paths prevent manifest collisions across test and development")
      end
    end

    def add_shared_output_path_procfile_guidance
      return unless procfile_dev_uses_dev_server?

      procfile_dev_label = Dev::ServerMode.text(default_dev_server_mode, :procfile_dev_label)

      if static_procfile_available?
        checker.add_warning(
          "  ⚠️  #{procfile_dev_label} is present. Shared output path is high-risk " \
          "unless you run bin/dev static."
        )
        checker.add_info("  💡 Use: ./bin/dev static")
        checker.add_info("  💡 For test watch in this setup: ./bin/dev test-watch --test-watch-mode=client-only")
      else
        checker.add_error(
          "  🚫 Shared output path + #{procfile_dev_label} detected, " \
          "but Procfile.dev-static-assets is missing"
        )
        checker.add_info("  💡 Fix: separate test/development public_output_path values, or add static Procfile support")
      end
    end

    def procfile_dev_uses_dev_server?
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
      Dev::ServerMode.hmr_enabled?(shakapacker_config_path)
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
        "  💡 With shared output paths, only use bin/dev static " \
        "(not #{Dev::ServerMode.text(default_dev_server_mode, :next_step_label)}) when running Capybara tests"
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
        "  💡 Both bin/dev (#{Dev::ServerMode.text(default_dev_server_mode, :next_step_label)}) " \
        "and bin/dev static work in this mode"
      )
    end

    def report_capybara_standard_mode
      return unless capybara_configured?

      checker.add_info(
        "  💡 Capybara starts its own server — dev-server assets won't work. " \
        "Use bin/dev static or precompile."
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
      checker.add_info("  📖 https://reactonrails.com/docs/configuration/")
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

        Configuration diagnostics may reflect default values instead of your app's runtime configuration.
      MSG
      false
    end

    def react_on_rails_runtime_configuration
      return @react_on_rails_runtime_configuration if defined?(@react_on_rails_runtime_configuration)

      @react_on_rails_runtime_configuration =
        ensure_rails_environment_loaded ? ReactOnRails.configuration : nil
    rescue StandardError, LoadError => e
      checker.add_warning("⚠️  Could not query React on Rails runtime configuration: #{e.message}")
      # Memoize as nil to avoid repeated failed lookups on subsequent checks.
      @react_on_rails_runtime_configuration = nil
    end

    def resolved_pro_server_renderer
      return @resolved_pro_server_renderer if defined?(@resolved_pro_server_renderer)
      return (@resolved_pro_server_renderer = nil) unless ReactOnRails::Utils.react_on_rails_pro?

      rails_environment_loaded = ensure_rails_environment_loaded
      @resolved_pro_server_renderer =
        if rails_environment_loaded && defined?(ReactOnRailsPro)
          # server_renderer is stored as a plain string in Pro config (for example, "NodeRenderer").
          ReactOnRailsPro.configuration.server_renderer.to_s
        elsif pro_initializer_has_node_renderer?
          "NodeRenderer"
        elsif rails_environment_loaded
          checker.add_warning(
            "⚠️  Could not determine Pro server renderer: ReactOnRailsPro is unavailable " \
            "and no initializer match found."
          )
          nil
        else
          checker.add_info(
            "ℹ️  Could not determine Pro server renderer: Rails environment unavailable and no initializer match found."
          )
          nil
        end
    rescue StandardError, LoadError => e
      checker.add_warning("⚠️  Could not read Pro runtime renderer configuration: #{e.message}")
      @resolved_pro_server_renderer = nil
    end

    def pro_execjs_fallback_enabled?
      return ReactOnRailsPro.configuration.renderer_use_fallback_exec_js if defined?(ReactOnRailsPro)

      config_path = "config/initializers/react_on_rails_pro.rb"
      return true unless File.exist?(config_path)

      content = File.read(config_path)
      fallback_match = content.match(/config\.renderer_use_fallback_exec_js\s*=\s*(true|false)/)
      fallback_match ? fallback_match[1] == "true" : true
    rescue StandardError, LoadError => e
      checker.add_warning("⚠️  Could not read Pro fallback ExecJS configuration: #{e.message}")
      true
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
      check_base_package_references
      check_deprecated_renderer_cache_task
      check_rolling_deploy_adapter
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

    def check_deprecated_renderer_cache_task
      # Resolve against Rails.root (not Dir.pwd) so the scan still fires when
      # doctor is invoked from a subdirectory — otherwise the checks silently
      # find nothing and the deprecation warning never surfaces.
      #
      # Read in binary mode (the task name is pure ASCII) so a non-UTF-8 byte
      # in a deploy script does not raise Encoding::InvalidByteSequenceError
      # and mask the file via the rescue below.
      #
      # Skip leading-comment lines (`#` is the comment prefix for all scanned
      # file types: Procfile, Dockerfile, shell scripts, YAML, and Ruby) so
      # files that mention the old task only inside a comment do not trip the
      # migration nudge.
      # Per-file rescue so a transient failure on one path (e.g. Errno::EACCES)
      # does not abort the whole scan and silently skip the rest. The outer
      # rescue catches anything that escapes the per-file guard. Globs are
      # expanded under their own rescue so a failure expanding one pattern
      # cannot stop other patterns or fixed paths from being scanned.
      candidate_paths = (
        RENDERER_CACHE_DEPLOY_SCRIPT_PATHS + expand_renderer_cache_deploy_script_globs
      ).uniq

      matches = candidate_paths.select do |path|
        deploy_script_path_references_deprecated_task?(path)
      end

      return if matches.empty?

      checker.add_warning(<<~MSG.strip)
        ⚠️  Deprecated rake task '#{DEPRECATED_RENDERER_CACHE_TASK}' referenced in:
        #{matches.map { |p| format_renderer_cache_migration_bullet(p) }.join("\n")}

        The unified 'pre_seed_renderer_cache' task uses MODE=copy by default (for
        Docker/image builds) and MODE=symlink for same-filesystem workflows.
      MSG
    rescue StandardError => e
      checker.add_warning("⚠️  Could not complete scan for deprecated renderer-cache task references: #{e.message}")
    end

    def deploy_script_references_deprecated_task?(full_path, path)
      comment_prefixes = renderer_cache_deploy_script_comment_prefixes(path)

      # The trailing-comment strip requires whitespace before the comment marker,
      # so fragments like `task#name` stay intact while `cmd # was: <deprecated>`
      # and Jenkinsfile `cmd // was: <deprecated>` comments are filtered.
      full_path.binread.each_line.any? do |line|
        stripped = line.lstrip
        next false if comment_prefixes.any? { |prefix| stripped.start_with?(prefix) }

        without_inline_comment = comment_prefixes.reduce(stripped) do |content, prefix|
          content.sub(/ +#{Regexp.escape(prefix)}.*/, "")
        end
        without_inline_comment.include?(DEPRECATED_RENDERER_CACHE_TASK)
      end
    end

    def renderer_cache_deploy_script_comment_prefixes(path)
      return ["#", "//"] if path == "Jenkinsfile"

      ["#"]
    end

    def deploy_script_path_references_deprecated_task?(path)
      full_path = Rails.root.join(path)

      return false unless full_path.file?
      # Skip files larger than RENDERER_CACHE_DEPLOY_SCRIPT_MAX_BYTES;
      # deploy scripts and CI manifests should be tiny.
      return false if full_path.size > RENDERER_CACHE_DEPLOY_SCRIPT_MAX_BYTES

      deploy_script_references_deprecated_task?(full_path, path)
    rescue StandardError => e
      checker.add_warning(
        "⚠️  Could not scan #{path} for deprecated renderer-cache task references: #{e.message}"
      )
      false
    end

    def expand_renderer_cache_deploy_script_globs
      # File::FNM_PATHNAME stops `*` from crossing slashes even though none of
      # the patterns use `**`. base: scopes the expansion to the project root
      # and yields paths relative to it. Each pattern is rescued individually
      # so a permission error on one glob (e.g. an unreadable .github/) does
      # not silence the rest.
      root = Rails.root.to_s
      RENDERER_CACHE_DEPLOY_SCRIPT_GLOBS.flat_map do |pattern|
        Dir.glob(pattern, File::FNM_PATHNAME, base: root)
           .sort
           .first(RENDERER_CACHE_DEPLOY_SCRIPT_GLOB_MAX_MATCHES)
      rescue StandardError => e
        checker.add_warning(
          "⚠️  Could not expand renderer-cache deploy-script glob #{pattern}: #{e.message}"
        )
        []
      end
    end

    def format_renderer_cache_migration_bullet(path)
      suggestion = renderer_cache_migration_suggestion(path)
      lines = suggestion.split("\n")
      return "  • #{path} → #{suggestion}" if lines.length == 1

      indented = lines.map { |line| "      #{line}" }.join("\n")
      "  • #{path} →\n#{indented}"
    end

    def renderer_cache_migration_suggestion(path)
      # Dockerfile* entries are RUN steps during image build, so copy mode bakes the cache into the layer.
      # Runtime hooks (Procfile, bin/*, .kamal/deploy.yml, Capistrano config) run after the app is deployed,
      # where both the app and renderer share the same filesystem, so symlink mode is correct.
      if path.start_with?("Dockerfile")
        # /app/.node-renderer-bundles is a placeholder matching the docs' Dockerfile examples;
        # the user must adjust it to match their image's WORKDIR. Hardcoding Rails.root here would
        # leak the developer host path (e.g. /Users/alice/myapp/...) into the Dockerfile, which
        # does not exist inside the container.
        "ENV RENDERER_SERVER_BUNDLE_CACHE_PATH=/app/.node-renderer-bundles\n" \
          "RUN bundle exec rake react_on_rails_pro:pre_seed_renderer_cache"
      elsif path.start_with?(".kamal/")
        # Kamal hooks run in two contexts: post-deploy hooks on the live server (symlink),
        # and image-build hooks invoked during the Docker build (copy). The trailing comments
        # disambiguate so users pick the mode that matches the hook they're editing.
        "rake react_on_rails_pro:pre_seed_renderer_cache MODE=symlink\n" \
          "# For Kamal deploy hooks (post-deploy, on the live server): MODE=symlink\n" \
          "# For Kamal image-build hooks (hook/pre-build inside the Docker build): MODE=copy"
      else
        # docker-compose.yml / compose.yaml / bin/* / config/deploy.rb / scripts/deploy.sh
        # default to symlink (correct for local dev + same-filesystem deploys); call out the
        # copy alternative for users driving production container builds via Compose.
        "rake react_on_rails_pro:pre_seed_renderer_cache MODE=symlink # use MODE=copy for Docker/container image builds"
      end
    end

    # ── Rolling Deploy Adapter ────────────────────────────────────────

    ROLLING_DEPLOY_REQUIRED_METHODS = %i[previous_bundle_hashes fetch upload].freeze

    def check_rolling_deploy_adapter
      adapter = ReactOnRailsPro.configuration.rolling_deploy_adapter

      if adapter.nil?
        env_override = ENV.fetch("PREVIOUS_BUNDLE_HASHES", nil)
        if env_override && !env_override.empty?
          checker.add_warning(
            "⚠️  PREVIOUS_BUNDLE_HASHES=#{truncate_for_warning(env_override).inspect} is set but no " \
            "rolling_deploy_adapter is configured. Rolling-deploy seeding needs both — the env var " \
            "overrides *discovery* but the adapter is still required to fetch bundle files. " \
            "Set config.rolling_deploy_adapter or unset PREVIOUS_BUNDLE_HASHES."
          )
        else
          checker.add_info("ℹ️  No rolling_deploy_adapter configured (rolling-deploy seeding disabled).")
        end
        return
      end

      return unless report_adapter_protocol(adapter)

      env_override = ENV.fetch("PREVIOUS_BUNDLE_HASHES", nil)
      if env_override && !env_override.empty?
        # PREVIOUS_BUNDLE_HASHES is a full discovery override at runtime, so
        # probing adapter#previous_bundle_hashes here would surface timeout/error
        # noise for a code path the deploy will never invoke. Skip the probe and
        # state the override explicitly so operators see what's happening.
        checker.add_info(
          "ℹ️  PREVIOUS_BUNDLE_HASHES=#{truncate_for_warning(env_override).inspect} is set; " \
          "skipping rolling_deploy_adapter#previous_bundle_hashes probe (env var overrides discovery)."
        )
        report_resolved_cache_dir
        return
      end

      report_previous_bundle_hashes_probe(adapter)
      report_resolved_cache_dir
    rescue StandardError => e
      checker.add_warning("⚠️  Could not evaluate rolling_deploy_adapter: #{e.message}")
    end

    # Cap echoed env-var values so a malformed (or accidentally large)
    # PREVIOUS_BUNDLE_HASHES value doesn't dump kilobytes into operator output.
    PREVIOUS_BUNDLE_HASHES_DISPLAY_LIMIT = 80
    private_constant :PREVIOUS_BUNDLE_HASHES_DISPLAY_LIMIT

    def truncate_for_warning(value)
      return value if value.length <= PREVIOUS_BUNDLE_HASHES_DISPLAY_LIMIT

      "#{value[0, PREVIOUS_BUNDLE_HASHES_DISPLAY_LIMIT]}… (#{value.length} chars total)"
    end

    def report_adapter_protocol(adapter)
      missing = ROLLING_DEPLOY_REQUIRED_METHODS.reject { |m| adapter.respond_to?(m) }
      if missing.empty?
        checker.add_success(
          "✅ rolling_deploy_adapter responds to all required methods " \
          "(#{ROLLING_DEPLOY_REQUIRED_METHODS.join(', ')})"
        )
        true
      else
        checker.add_warning(
          "⚠️  rolling_deploy_adapter is missing required methods: #{missing.join(', ')}. " \
          "See docs/pro/rolling-deploy-adapters.md."
        )
        false
      end
    end

    def report_previous_bundle_hashes_probe(adapter)
      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      timeout_seconds = rolling_deploy_discovery_timeout_seconds
      hashes = Timeout.timeout(timeout_seconds) { Array(adapter.previous_bundle_hashes) }
      latency_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000).round

      if hashes.empty?
        checker.add_warning(
          "⚠️  rolling_deploy_adapter#previous_bundle_hashes returned []. " \
          "Usually indicates the upload side has never run on a prior deploy."
        )
      else
        checker.add_success(
          "✅ rolling_deploy_adapter#previous_bundle_hashes returned #{hashes.length} hash(es) in #{latency_ms}ms"
        )
      end
    rescue Timeout::Error
      checker.add_warning(
        "⚠️  rolling_deploy_adapter#previous_bundle_hashes timed out after " \
        "#{timeout_seconds}s"
      )
    rescue StandardError => e
      checker.add_warning("⚠️  rolling_deploy_adapter#previous_bundle_hashes raised #{e.class}: #{e.message}")
    end

    def rolling_deploy_discovery_timeout_seconds
      if defined?(ReactOnRailsPro::RollingDeployCacheStager::DISCOVERY_TIMEOUT_SECONDS)
        ReactOnRailsPro::RollingDeployCacheStager::DISCOVERY_TIMEOUT_SECONDS
      else
        # Must match the canonical Pro constant. Bidirectional pointers:
        #   Pro file:     react_on_rails_pro/lib/react_on_rails_pro/rolling_deploy_cache_stager.rb
        #   Pro constant: ReactOnRailsPro::RollingDeployCacheStager::DISCOVERY_TIMEOUT_SECONDS
        #   Pro guard:    react_on_rails_pro/spec/dummy/spec/rolling_deploy_cache_stager_spec.rb
        #                 (describe "DISCOVERY_TIMEOUT_SECONDS" → expects this fallback to equal Pro constant)
        # The Pro spec catches drift in the Pro→OSS direction. If you change
        # the value here without updating the Pro constant + spec, doctor will
        # silently use a different timeout from the live stager.
        10
      end
    end

    # Fallback used when the Pro gem isn't loaded. Must match
    # ReactOnRailsPro::RollingDeployCacheStager::TEMPORARY_DIRECTORY_PATTERN so
    # doctor still filters staging/backup dirs out of the bundle-hash count.
    # Drift is caught by:
    #   react_on_rails_pro/spec/dummy/spec/rolling_deploy_cache_stager_spec.rb
    #   describe "TEMPORARY_DIRECTORY_PATTERN"
    # PID is `\d+` to match container deployments (Docker/Kubernetes) where
    # seeding runs as PID 1.
    ROLLING_DEPLOY_TEMP_DIR_PATTERN = /\.(?:staging|previous)-\d+-[0-9a-f]{8,}\z/

    def report_resolved_cache_dir
      cache_dir = ReactOnRailsPro::Utils.resolve_renderer_cache_dir
      if File.directory?(cache_dir)
        temp_dir_pattern = rolling_deploy_temp_dir_pattern
        subdirs = Dir.children(cache_dir).select do |entry|
          File.directory?(File.join(cache_dir, entry)) && !entry.match?(temp_dir_pattern)
        end
        checker.add_info("ℹ️  Resolved renderer cache dir: #{cache_dir} (#{subdirs.length} bundle-hash subdir(s))")
      else
        checker.add_info("ℹ️  Resolved renderer cache dir: #{cache_dir} (does not exist yet)")
      end
    end

    def rolling_deploy_temp_dir_pattern
      if defined?(ReactOnRailsPro::RollingDeployCacheStager::TEMPORARY_DIRECTORY_PATTERN)
        ReactOnRailsPro::RollingDeployCacheStager::TEMPORARY_DIRECTORY_PATTERN
      else
        ROLLING_DEPLOY_TEMP_DIR_PATTERN
      end
    end

    # The base 'react-on-rails' npm package is a transitive dependency of 'react-on-rails-pro',
    # so references to 'react-on-rails' resolve silently, loading the base package instead of Pro.
    # Components registered through the base package won't have Pro features (streaming, caching,
    # RSC), and may cause "component not registered" errors at runtime.
    BASE_PACKAGE_IMPORT_PATTERN = %r{\bfrom\s+['"]react-on-rails(?:/[^'"]*)?['"]}
    BASE_PACKAGE_REQUIRE_PATTERN = %r{\brequire\s*\(\s*['"]react-on-rails(?:/[^'"]*)?['"]\s*\)}
    BASE_PACKAGE_DYNAMIC_IMPORT_PATTERN = %r{\bimport\s*\(\s*['"]react-on-rails(?:/[^'"]*)?['"]\s*\)}
    BASE_PACKAGE_SIDE_EFFECT_IMPORT_PATTERN = %r{^\s*import\s+['"]react-on-rails(?:/[^'"]*)?['"]}
    BASE_PACKAGE_REFERENCE_SOURCE_ROOTS = ReactOnRails::ProMigration::JS_SOURCE_ROOTS
    BASE_PACKAGE_REFERENCE_EXTENSIONS = ReactOnRails::ProMigration::JS_SOURCE_EXTENSIONS
    # Explicit allowlist of documented Jest/Vitest APIs whose first argument is a module specifier.
    BASE_PACKAGE_JEST_MODULE_SPECIFIER_METHOD_PATTERN =
      ReactOnRails::ProMigration::JEST_MODULE_SPECIFIER_METHOD_PATTERN
    BASE_PACKAGE_VITEST_MODULE_SPECIFIER_METHOD_PATTERN =
      ReactOnRails::ProMigration::VITEST_MODULE_SPECIFIER_METHOD_PATTERN
    # Match known Jest/Vitest module-specifier helpers. Aliased or nested receivers
    # are intentionally out of scope to avoid warning on arbitrary application methods.
    #
    # importActual/importMock exist only as vi.* methods; there is no
    # `import { importActual } from 'vitest'` form. The bare branch below is a
    # deliberately broad detector heuristic (the rewriter omits it because
    # rewriting is destructive while detection is advisory) and accepts that a
    # user-defined helper of that name taking a 'react-on-rails' string matches.
    BASE_PACKAGE_MOCK_PATTERN = %r{
      \b(?:
        (?:
          jest\.(?:#{BASE_PACKAGE_JEST_MODULE_SPECIFIER_METHOD_PATTERN})
          |
          vi\.(?:#{BASE_PACKAGE_VITEST_MODULE_SPECIFIER_METHOD_PATTERN})
        )
        \s*
        (?:<[^;\n]*>\s*)?
        |
        (?:importActual|importMock)
      )
      \s*\(\s*['"]react-on-rails(?:/[^'"]*)?['"]
    }x
    # In Ruby, ^ matches the start of any line, so this catches declarations anywhere in the file.
    BASE_PACKAGE_DECLARE_MODULE_PATTERN = %r{^\s*(?:export\s+)?declare\s+module\s+['"]react-on-rails(?:/[^'"]*)?['"]}
    BASE_PACKAGE_REFERENCE_PATTERNS = [
      BASE_PACKAGE_IMPORT_PATTERN,
      BASE_PACKAGE_REQUIRE_PATTERN,
      BASE_PACKAGE_DYNAMIC_IMPORT_PATTERN,
      BASE_PACKAGE_SIDE_EFFECT_IMPORT_PATTERN,
      BASE_PACKAGE_MOCK_PATTERN,
      BASE_PACKAGE_DECLARE_MODULE_PATTERN
    ].freeze

    def check_base_package_references
      files_with_base_reference = files_with_base_package_references(resolve_js_source_path)

      if files_with_base_reference.empty?
        checker.add_success("✅ No base 'react-on-rails' references found (Pro package used correctly)")
      else
        checker.add_warning(<<~MSG.strip)
          ⚠️  Found references to 'react-on-rails' instead of 'react-on-rails-pro':
          #{files_with_base_reference.map { |f| "  • #{f}" }.join("\n")}

          Look for static imports, side-effect imports, CommonJS requires, dynamic imports,
          Jest/Vitest mock helpers, or TypeScript module augmentations.
          Note: this includes commented-out references; review each file before updating.

          The base package is a transitive dependency of Pro, so these references resolve
          silently but load the base version without Pro features.

          Fix: Replace base-package references with their Pro equivalents:
            import ReactOnRails from 'react-on-rails-pro';         // ES import (server)
            import ReactOnRails from 'react-on-rails-pro/client';  // ES import (client)
            import 'react-on-rails-pro';                           // Side-effect import
            const ReactOnRails = require('react-on-rails-pro');    // CommonJS require
            const ReactOnRails = await import('react-on-rails-pro'); // Dynamic import
            jest.mock('react-on-rails-pro', ...);                  // Jest mock helper
            vi.mock('react-on-rails-pro', ...);                    // Vitest mock helper
            declare module 'react-on-rails-pro' { ... }            // TypeScript augmentation
        MSG
      end
    rescue StandardError => e
      checker.add_warning("⚠️  Could not scan for base package references: #{e.message}")
    end

    def files_with_base_package_references(source_path)
      # Scan every file type the Pro migration rewriter can modify.
      # **/*.ts naturally matches *.d.ts declaration files because they end in .ts.
      js_patterns = base_package_reference_source_paths(source_path).flat_map do |source_root|
        BASE_PACKAGE_REFERENCE_EXTENSIONS.map { |ext| "#{source_root}/**/*.#{ext}" }
      end

      js_patterns.flat_map do |pattern|
        Dir.glob(pattern)
           .reject { |file| file.include?("/node_modules/") }
           .select { |file| base_package_reference_file?(file) }
      end.uniq.sort
    end

    def base_package_reference_source_paths(source_path)
      ([source_path] + BASE_PACKAGE_REFERENCE_SOURCE_ROOTS)
        .compact
        .map(&:to_s)
        .reject(&:empty?)
        .uniq
        .select { |path| Dir.exist?(path) }
    end

    def base_package_reference_file?(file)
      content = File.binread(file).force_encoding("UTF-8")
      return false unless content.valid_encoding?

      base_package_reference?(content)
    rescue SystemCallError, IOError
      false
    end

    def base_package_reference?(content)
      # Content-based matching intentionally catches comments and string literals
      # so stale migration references stay visible.
      BASE_PACKAGE_REFERENCE_PATTERNS.any? { |reference_pattern| content.match?(reference_pattern) }
    end

    # ── React Server Components ────────────────────────────────────

    # Candidate paths for RSC bundler configuration (webpack and rspack variants)
    RSC_BUNDLER_CONFIG_PATHS = %w[
      config/webpack/rscWebpackConfig.js
      config/rspack/rscWebpackConfig.js
    ].freeze
    RSC_PACKAGE_NAME = "react-on-rails-rsc"
    RSC_DIST_TAGS_TO_CHECK = %w[next rc].freeze
    NPM_VIEW_FETCH_TIMEOUT_MS = 5_000
    NPM_VIEW_FETCH_TIMEOUT_SECONDS = NPM_VIEW_FETCH_TIMEOUT_MS / 1000.0
    NPM_VIEW_TERMINATION_GRACE_SECONDS = 0.5
    # npm registry package names used here must be lowercase; keep this allowlist
    # narrow so names remain safe when reused as Node resolver args and paths.
    PACKAGE_NAME_PATTERN = %r{
      \A
      (?:@[a-z0-9][a-z0-9._-]*/)?
      [a-z0-9][a-z0-9._-]*
      \z
    }x
    # Keep in sync with RSC_CLIENT_MANIFEST_GUIDANCE in
    # packages/react-on-rails-pro/src/handleErrorRSC.ts.
    RSC_CLIENT_MANIFEST_CLEANUP_PATHS = %w[public/packs public/packs-test ssr-generated .node-renderer-bundles].freeze

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
      check_rsc_client_manifest
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

    def check_rsc_react_version
      react_version = detect_react_version_from_deps
      unless react_version
        checker.add_info("ℹ️  Could not detect React version — skipping RSC version check")
        return
      end

      package_root = resolved_package_root
      return if check_rsc_package_compatibility_if_present(package_root, react_version)

      check_legacy_rsc_react_version(react_version)
    end

    def check_legacy_rsc_react_version(react_version)
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

    def check_rsc_package_compatibility_if_present(package_root, react_version)
      return false unless declared_package_spec(RSC_PACKAGE_NAME)

      rsc_package = installed_package_json(package_root, RSC_PACKAGE_NAME)
      unless rsc_package
        checker.add_error(<<~MSG.strip)
          🚫 #{RSC_PACKAGE_NAME} is declared in package.json but could not be resolved from node_modules.

          React Server Components require the installed #{RSC_PACKAGE_NAME} package to validate React peer compatibility.

          Fix: install dependencies in the JavaScript package root, for example:
            npm install
        MSG
        return true
      end

      unless rsc_package_declares_react_peer_dependencies?(rsc_package)
        checker.add_warning(<<~MSG.strip)
          ⚠️  #{RSC_PACKAGE_NAME} #{rsc_package['version']} does not declare React peer dependencies.

          Falling back to the legacy React version heuristic.
        MSG
        return false
      end

      peer_compatible = check_rsc_package_peer_compatibility(rsc_package, react_version)

      if peer_compatible && vulnerable_legacy_rsc_react_version?(react_version)
        check_legacy_rsc_react_version(react_version)
      end
      check_rsc_package_dist_tags(rsc_package, package_root)
      true
    end

    def vulnerable_legacy_rsc_react_version?(react_version)
      major, minor, patch = react_version.split(".").map(&:to_i)
      major == 19 && minor.zero? && patch < 4
    end

    def rsc_package_declares_react_peer_dependencies?(rsc_package)
      peer_dependencies = rsc_package["peerDependencies"] || {}
      peer_dependencies["react"].present? || peer_dependencies["react-dom"].present?
    end

    def check_rsc_package_peer_compatibility(rsc_package, react_version)
      rsc_version = rsc_package["version"].to_s
      peer_dependencies = rsc_package["peerDependencies"] || {}
      react_peer_range = peer_dependencies["react"]
      react_dom_peer_range = peer_dependencies["react-dom"]

      peer_checks = rsc_peer_check_results(
        react_version:,
        react_peer_range:,
        react_dom_peer_range:,
        rsc_version:
      )
      return false if peer_checks.empty?

      if peer_checks.all?
        checker.add_success(
          "✅ #{RSC_PACKAGE_NAME} #{rsc_version} peer dependencies are compatible with React #{react_version}"
        )
        true
      else
        false
      end
    end

    def rsc_peer_check_results(react_version:, react_peer_range:, react_dom_peer_range:, rsc_version:)
      results = []
      if react_peer_range.present?
        results << check_rsc_peer_package(
          package_name: "react",
          installed_version: react_version,
          peer_range: react_peer_range,
          rsc_version:
        )
      end
      if react_dom_peer_range.present?
        results << check_rsc_peer_package(
          package_name: "react-dom",
          installed_version: detect_package_version_from_deps("react-dom"),
          peer_range: react_dom_peer_range,
          rsc_version:
        )
      end
      results
    end

    def check_rsc_peer_package(package_name:, installed_version:, peer_range:, rsc_version:)
      unless installed_version
        checker.add_error(<<~MSG.strip)
          🚫 #{RSC_PACKAGE_NAME} #{rsc_version} requires #{package_name} #{peer_range}, but #{package_name} is not installed or could not be detected.

          Fix: install #{package_name} in the JavaScript package root configured by ReactOnRails.configuration.node_modules_location.
        MSG
        return false
      end

      return true if npm_range_satisfied?(installed_version, peer_range)

      checker.add_error(<<~MSG.strip)
        🚫 #{RSC_PACKAGE_NAME} #{rsc_version} requires #{package_name} #{peer_range}, but installed #{package_name} is #{installed_version}.

        React Server Components depend on React internal server APIs that can change between React minors.

        Fix: install matching versions, for example:
          npm install #{package_name}@#{peer_range} #{RSC_PACKAGE_NAME}@#{rsc_version} --save-exact
      MSG
      false
    end

    def check_rsc_package_dist_tags(rsc_package, package_root)
      installed_version = rsc_package["version"].to_s
      return if installed_version.blank?

      rsc_dist_tags(package_root).each do |tag, tag_version|
        next unless RSC_DIST_TAGS_TO_CHECK.include?(tag)
        next unless npm_version_greater?(tag_version, installed_version)

        checker.add_warning(<<~MSG.strip)
          ⚠️  #{RSC_PACKAGE_NAME} #{installed_version} is behind the npm #{tag} dist-tag #{tag_version}.

          React Server Components track React minor versions. If your React version is on the #{tag_version.split('.')[0, 2].join('.')} line, install the matching RSC package instead of relying on a stale latest tag.

          Check peer requirements with:
            npm view #{RSC_PACKAGE_NAME}@#{tag_version} peerDependencies
        MSG
      end
    end

    def rsc_dist_tags(package_root)
      @rsc_dist_tags_cache ||= {}
      return @rsc_dist_tags_cache[package_root] if @rsc_dist_tags_cache.key?(package_root)

      @rsc_dist_tags_cache[package_root] = fetch_rsc_dist_tags(package_root)
    end

    def fetch_rsc_dist_tags(package_root)
      checker.add_info("  ℹ️  Checking #{RSC_PACKAGE_NAME} npm dist-tags to flag stale RSC pins")
      stdout, status = capture_rsc_dist_tags(package_root)
      unless status&.success?
        report_rsc_dist_tag_lookup_skipped(package_root)
        return {}
      end

      tags = JSON.parse(stdout)
      return tags if tags.is_a?(Hash)

      report_rsc_dist_tag_lookup_skipped(package_root)
      {}
    rescue StandardError
      report_rsc_dist_tag_lookup_skipped(package_root)
      {}
    end

    def report_rsc_dist_tag_lookup_skipped(package_root)
      @rsc_dist_tag_lookup_skipped_reported ||= {}
      return if @rsc_dist_tag_lookup_skipped_reported[package_root]

      checker.add_info("  ℹ️  Could not fetch #{RSC_PACKAGE_NAME} dist-tags from npm; skipping stale-tag check")
      @rsc_dist_tag_lookup_skipped_reported[package_root] = true
    end

    def capture_rsc_dist_tags(package_root)
      stdout_r, stdout_w = IO.pipe
      stderr_r, stderr_w = IO.pipe
      stdout_thread = nil
      stderr_thread = nil
      pid = nil
      process_reaped = false

      begin
        pid = Process.spawn(*rsc_dist_tag_command, chdir: package_root, out: stdout_w, err: stderr_w, pgroup: true)
        stdout_w.close
        stdout_w = nil
        stderr_w.close
        stderr_w = nil

        stdout_thread = read_pipe_async(stdout_r)
        stderr_thread = read_pipe_async(stderr_r)
        status = wait_for_rsc_dist_tag_process(pid)
        process_reaped = true
        if status
          stdout = stdout_thread.value
          stderr_thread.value
        else
          close_io(stdout_r)
          close_io(stderr_r)
          stdout = ""
        end

        [stdout, status]
      ensure
        close_io(stdout_w)
        close_io(stderr_w)
        close_io(stdout_r)
        close_io(stderr_r)
        stdout_thread&.join(0.1)
        stderr_thread&.join(0.1)
        cleanup_rsc_dist_tag_process(pid, process_reaped)
      end
    end

    def cleanup_rsc_dist_tag_process(pid, process_reaped)
      return if pid.nil? || process_reaped

      terminate_rsc_dist_tag_process(pid)
    end

    def rsc_dist_tag_command
      [
        "npm",
        "view",
        RSC_PACKAGE_NAME,
        "dist-tags",
        "--json",
        "--fetch-timeout=#{NPM_VIEW_FETCH_TIMEOUT_MS}"
      ]
    end

    def read_pipe_async(pipe)
      thread = Thread.new do
        pipe.read
      rescue IOError, SystemCallError
        ""
      end
      thread.report_on_exception = false if thread.respond_to?(:report_on_exception=)
      thread
    end

    def wait_for_rsc_dist_tag_process(pid)
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + NPM_VIEW_FETCH_TIMEOUT_SECONDS
      loop do
        _waited_pid, status = Process.wait2(pid, Process::WNOHANG)
        return status if status

        if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
          terminate_rsc_dist_tag_process(pid)
          return nil
        end

        sleep 0.05
      end
    rescue Errno::ECHILD, Errno::ESRCH
      nil
    end

    def terminate_rsc_dist_tag_process(pid)
      signal_rsc_dist_tag_process("TERM", pid)
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + NPM_VIEW_TERMINATION_GRACE_SECONDS
      loop do
        _waited_pid, status = Process.wait2(pid, Process::WNOHANG)
        return if status || Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline

        sleep 0.05
      end

      signal_rsc_dist_tag_process("KILL", pid)
      Process.wait(pid)
    rescue Errno::ECHILD, Errno::ESRCH
      nil
    end

    def signal_rsc_dist_tag_process(signal, pid)
      Process.kill(signal, -pid)
    rescue Errno::ESRCH, Errno::EINVAL
      Process.kill(signal, pid)
    end

    def close_io(io)
      io.close if io && !io.closed?
    rescue IOError
      nil
    end

    def npm_range_satisfied?(version, range)
      range.to_s.split("||").any? do |range_clause|
        npm_range_clause_satisfied?(version, range_clause.strip)
      end
    end

    def npm_range_clause_satisfied?(version, range_clause)
      return false if range_clause.blank?
      return true if range_clause.match?(/\A[~^]?\s*[*xX](?:\.[*xX]){0,2}\z/)

      hyphen_range_satisfied = npm_hyphen_range_result(version, range_clause)
      return hyphen_range_satisfied unless hyphen_range_satisfied.nil?

      x_range_satisfied = npm_x_range_result(version, range_clause)
      return x_range_satisfied unless x_range_satisfied.nil?

      npm_comparators_range_result(version, range_clause)
    end

    def npm_comparators_range_result(version, range_clause)
      comparators = range_clause.scan(/(?:>=|<=|>|<|=|\^|~)?\s*v?\d+(?:\.\d+){0,2}(?:-[0-9A-Za-z.-]+)?/)
      return false if comparators.empty?

      target_versions = comparators.map { |comparator| npm_comparator_target_version(comparator.strip) }
      return false unless npm_prerelease_allowed_by_versions?(version, target_versions)

      comparators.all? { |comparator| npm_comparator_satisfied?(version, comparator.strip) }
    end

    def npm_x_range_result(version, range_clause)
      match = npm_x_range_match(range_clause)
      return nil unless match
      return false if npm_prerelease(version).present?

      segments = [match[:major], match[:minor], match[:patch]]
      wildcard_index = segments.index { |segment| npm_wildcard_version_segment?(segment) }
      return nil unless wildcard_index
      return true if wildcard_index.zero?

      major = segments[0].to_i
      minor = wildcard_index >= 2 ? segments[1].to_i : 0
      lower_bound = "#{major}.#{minor}.0"
      upper_bound = npm_x_range_upper_bound(match[:operator], wildcard_index, major, minor, lower_bound)

      npm_version_compare(version, lower_bound) >= 0 && npm_version_less_than?(version, upper_bound)
    end

    def npm_x_range_match(range_clause)
      range_clause.match(
        /
          \A\s*
          (?<operator>[=~^]?)\s*
          v?
          (?<major>\d+|[*xX])
          (?:\.(?<minor>\d+|[*xX]))?
          (?:\.(?<patch>\d+|[*xX]))?
          \s*\z
        /x
      )
    end

    def npm_wildcard_version_segment?(segment)
      segment.blank? || segment.match?(/\A[*xX]\z/)
    end

    def npm_x_range_upper_bound(operator, wildcard_index, major, minor, lower_bound)
      return npm_caret_x_range_upper_bound(wildcard_index, major, minor, lower_bound) if operator == "^"
      return "#{major + 1}.0.0" if wildcard_index == 1

      "#{major}.#{minor + 1}.0"
    end

    def npm_caret_x_range_upper_bound(wildcard_index, major, minor, lower_bound)
      if wildcard_index == 1
        return major.positive? ? "#{major + 1}.0.0" : "1.0.0"
      end
      return "#{major}.#{minor + 1}.0" if wildcard_index == 2 && major.zero? && minor.zero?

      npm_caret_upper_bound(lower_bound)
    end

    def npm_hyphen_range_result(version, range_clause)
      match = range_clause.match(
        /
          \A\s*
          (?<lower>v?\d+(?:\.\d+){0,2}(?:-[0-9A-Za-z.-]+)?)
          \s+-\s*
          (?<upper>v?\d+(?:\.\d+){0,2}(?:-[0-9A-Za-z.-]+)?)
          \s*\z
        /x
      )
      return nil unless match
      return false unless npm_prerelease_allowed_by_versions?(version, [match[:lower], match[:upper]])

      npm_version_compare(version, npm_normalize_partial_version(match[:lower])) >= 0 &&
        npm_hyphen_upper_bound_satisfied?(version, match[:upper])
    end

    def npm_hyphen_upper_bound_satisfied?(version, upper_bound)
      normalized_upper_bound = npm_normalize_partial_version(upper_bound)
      if npm_version_segment_count(upper_bound) >= 3 || npm_prerelease(upper_bound).present?
        npm_version_compare(version, normalized_upper_bound) <= 0
      else
        npm_version_less_than?(version, npm_partial_upper_bound(upper_bound))
      end
    end

    def npm_comparator_satisfied?(version, comparator)
      operator = comparator[/\A(?:>=|<=|>|<|=|\^|~)/] || "="
      target_version = npm_comparator_target_version(comparator)
      comparison = npm_version_compare(version, target_version)

      case operator
      when "^"
        comparison >= 0 &&
          npm_version_less_than?(version, npm_caret_upper_bound(target_version))
      when "~"
        comparison >= 0 &&
          npm_version_less_than?(version, npm_tilde_upper_bound(target_version))
      else
        npm_plain_comparator_satisfied?(comparison, operator)
      end
    end

    def npm_comparator_target_version(comparator)
      comparator.sub(/\A(?:>=|<=|>|<|=|\^|~)\s*/, "")
    end

    def npm_prerelease_allowed_by_versions?(version, target_versions)
      return true if npm_prerelease(version).blank?

      version_tuple = npm_version_tuple(version)
      target_versions.any? do |target_version|
        npm_prerelease(target_version).present? && npm_version_tuple(target_version) == version_tuple
      end
    end

    def npm_plain_comparator_satisfied?(comparison, operator)
      case operator
      when ">="
        comparison >= 0
      when ">"
        comparison.positive?
      when "<="
        comparison <= 0
      when "<"
        comparison.negative?
      else
        comparison.zero?
      end
    end

    def npm_caret_upper_bound(version)
      major, minor, patch = npm_version_tuple(version)
      if major.positive?
        "#{major + 1}.0.0"
      elsif minor.positive?
        "0.#{minor + 1}.0"
      else
        "0.0.#{patch + 1}"
      end
    end

    def npm_tilde_upper_bound(version)
      major, minor, = npm_version_tuple(version)
      return "#{major}.#{minor + 1}.0" if npm_version_segment_count(version) > 1

      "#{major + 1}.0.0"
    end

    def npm_partial_upper_bound(version)
      major, minor, = npm_version_tuple(version)
      return "#{major + 1}.0.0" if npm_version_segment_count(version) <= 1

      "#{major}.#{minor + 1}.0"
    end

    def npm_version_greater?(left, right)
      npm_version_compare(left, right).positive?
    end

    def npm_version_less_than?(left, right)
      npm_version_compare(left, right).negative?
    end

    def npm_version_compare(left, right)
      left_tuple = npm_version_tuple(left)
      right_tuple = npm_version_tuple(right)

      left_tuple.zip(right_tuple).each do |left_part, right_part|
        comparison = left_part <=> right_part
        return comparison unless comparison.zero?
      end

      npm_prerelease_compare(npm_prerelease(left), npm_prerelease(right))
    end

    def npm_version_tuple(version)
      core = npm_version_core(version)
      parts = core.split(".").map(&:to_i)
      [parts[0] || 0, parts[1] || 0, parts[2] || 0]
    end

    def npm_normalize_partial_version(version)
      major, minor, patch = npm_version_tuple(version)
      prerelease = npm_prerelease(version)
      suffix = prerelease.present? ? "-#{prerelease}" : ""
      "#{major}.#{minor}.#{patch}#{suffix}"
    end

    def npm_version_segment_count(version)
      core = npm_version_core(version)
      return 0 if core.blank?

      core.split(".").length
    end

    def npm_version_core(version)
      version.to_s
             .delete_prefix("v")
             .split("+", 2).first.to_s
             .split("-", 2).first.to_s
    end

    def npm_prerelease(version)
      version.to_s.split("+", 2).first.to_s.split("-", 2)[1].to_s
    end

    def npm_prerelease_compare(left, right)
      return 0 if left == right
      return 1 if left.blank?
      return -1 if right.blank?

      npm_prerelease_segments_compare(left.split("."), right.split("."))
    end

    def npm_prerelease_segments_compare(left_parts, right_parts)
      [left_parts.length, right_parts.length].max.times do |index|
        left_part = left_parts[index]
        right_part = right_parts[index]
        return -1 if left_part.nil?
        return 1 if right_part.nil?

        comparison = npm_prerelease_part_compare(left_part, right_part)
        return comparison unless comparison.zero?
      end

      0
    end

    def npm_prerelease_part_compare(left_part, right_part)
      if left_part.match?(/\A\d+\z/) && right_part.match?(/\A\d+\z/)
        left_part.to_i <=> right_part.to_i
      else
        left_part <=> right_part
      end
    end

    def detect_react_version_from_deps
      # Prefer the actually installed version from node_modules over the declared
      # range in package.json. Declared ranges like "^19.0.0" would be misleading
      # (stripped to "19.0.0" even though 19.0.4+ may be installed).
      package_root = resolved_package_root
      if package_root_missing?(package_root)
        # This check only needs the directory before Node chdirs into it; an
        # installed React version can be resolved without package.json.
        warn_missing_package_root(package_root)
        return nil
      end

      installed = installed_react_version(package_root)
      return installed if installed

      declared_react_version
    rescue StandardError
      nil
    end

    def installed_react_version(package_root)
      installed_package_version(package_root, "react")
    end

    def detect_package_version_from_deps(package_name)
      package_root = resolved_package_root
      return nil if package_root_missing?(package_root)

      installed_package_version(package_root, package_name) || declared_package_version(package_name)
    rescue StandardError
      nil
    end

    def installed_package_version(package_root, package_name)
      version = installed_package_json(package_root, package_name)&.fetch("version", nil)
      version if version&.match?(/\A\d+\.\d+\.\d+/)
    end

    def installed_package_json(package_root, package_name)
      # Use Node's own module resolution to find the actually installed package,
      # which handles hoisted dependencies in monorepos and pnpm workspaces.
      # Resolve from the configured package root so nested client/ layouts work.
      return nil unless valid_package_name?(package_name)

      script = "console.log(require.resolve(process.argv[1] + '/package.json'))"
      stdout, _stderr, status = Open3.capture3("node", "-e", script, package_name, chdir: package_root)
      resolved_path = status.success? ? stdout.strip : ""
      # package_name has passed PACKAGE_NAME_PATTERN, so this fallback cannot escape node_modules.
      # It covers classic flat node_modules layouts; pnpm virtual-store layouts rely on Node resolution above.
      resolved_path = File.join(package_root, "node_modules", package_name, "package.json") if resolved_path.empty?
      return nil if resolved_path.empty? || !File.exist?(resolved_path)

      JSON.parse(File.read(resolved_path))
    rescue StandardError
      nil
    end

    def valid_package_name?(package_name)
      package_name.to_s.match?(PACKAGE_NAME_PATTERN)
    end

    def add_warning(message)
      checker.add_warning(message)
    end

    # Delegates the protected registry to checker so warnings emitted from
    # Doctor share the same de-dupe state as warnings emitted from the checker.
    # The cross-class call is permitted because both Doctor and SystemChecker
    # include ConfigPathResolver, which satisfies Ruby's protected-visibility
    # rule (caller and receiver share an ancestor that defines the method).
    def config_path_warning_registry
      checker.config_path_warning_registry
    end

    def declared_react_version
      declared_package_version("react")
    end

    def declared_package_version(package_name)
      version_str = declared_package_spec(package_name)
      return nil unless version_str

      clean_version = version_str.gsub(/\A[^0-9]*/, "")
      clean_version if clean_version.match?(/\A\d+\.\d+\.\d+\z/)
    rescue StandardError
      nil
    end

    def declared_package_spec(package_name)
      package_label = package_name == "react" ? "React" : package_name
      package_json_path = package_json_path_for("declared #{package_label} version")
      return nil unless package_json_path

      package_json = parsed_package_json(package_json_path)
      all_deps = (package_json["dependencies"] || {}).merge(package_json["devDependencies"] || {})
      all_deps[package_name]
    rescue StandardError
      nil
    end

    def parsed_package_json(package_json_path)
      @parsed_package_json_cache ||= {}
      @parsed_package_json_cache[package_json_path] ||= JSON.parse(File.read(package_json_path))
    end

    def check_rsc_client_manifest
      manifest_path = rsc_client_manifest_file_path
      unless manifest_path
        checker.add_warning("⚠️  RSC client manifest path could not be resolved — cannot verify client references")
        return
      end

      if manifest_url?(manifest_path)
        report_rsc_client_manifest_dev_server_url(manifest_path)
        return
      end

      unless File.exist?(manifest_path)
        report_missing_rsc_client_manifest(manifest_path)
        return
      end

      report_rsc_client_manifest_metadata(manifest_path)
    rescue JSON::ParserError => e
      checker.add_warning("⚠️  RSC client manifest is not valid JSON: #{e.message}")
      add_rsc_client_manifest_static_mode_guidance
    rescue StandardError => e
      checker.add_warning("⚠️  Could not inspect RSC client manifest: #{e.message}")
    end

    def rsc_client_manifest_file_path
      return nil unless defined?(ReactOnRailsPro::Utils)
      return nil unless ReactOnRailsPro::Utils.respond_to?(:react_client_manifest_file_path)

      ReactOnRailsPro::Utils.react_client_manifest_file_path
    end

    def manifest_url?(manifest_path)
      manifest_path.to_s.match?(%r{\Ahttps?://})
    end

    def report_rsc_client_manifest_dev_server_url(manifest_path)
      checker.add_warning("⚠️  RSC client manifest resolves to a dev-server URL: #{manifest_path}")
      add_rsc_client_manifest_static_mode_guidance
    end

    def report_missing_rsc_client_manifest(manifest_path)
      checker.add_warning("⚠️  RSC client manifest not found at #{manifest_path}")
      add_rsc_client_manifest_static_mode_guidance
    end

    def report_rsc_client_manifest_metadata(manifest_path)
      manifest_metadata = rsc_client_manifest_metadata(manifest_path)
      if manifest_metadata.nil?
        checker.add_warning("⚠️  RSC client manifest is missing filePathToModuleMetadata: #{manifest_path}")
      elsif manifest_metadata.empty?
        report_empty_rsc_client_manifest(manifest_path)
      else
        checker.add_success(
          "✅ RSC client manifest includes #{manifest_metadata.size} client reference metadata entries"
        )
      end
    end

    def report_empty_rsc_client_manifest(manifest_path)
      checker.add_warning(
        "⚠️  RSC client manifest has no client reference metadata: #{manifest_path}"
      )
      add_rsc_client_manifest_static_mode_guidance
    end

    def rsc_client_manifest_metadata(manifest_path)
      manifest = JSON.parse(File.read(manifest_path))
      metadata = manifest["filePathToModuleMetadata"]
      metadata if metadata.is_a?(Hash)
    end

    def add_rsc_client_manifest_static_mode_guidance
      checker.add_info("  💡 For RSC development, run: ./bin/dev static")
      checker.add_info(
        "  💡 If this followed an in-place package or React upgrade, stop the dev server and remove: " \
        "#{RSC_CLIENT_MANIFEST_CLEANUP_PATHS.join(', ')}"
      )
      checker.add_info("  💡 Then rebuild so the Node renderer reads a fresh on-disk React Client Manifest")
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
            rsc-bundle: RSC_BUNDLE_ONLY=true bin/shakapacker --watch

          If using a custom process manager, ensure the RSC bundle is built with
          the RSC_BUNDLE_ONLY=true environment variable.
        MSG
      end
    end
  end
  # rubocop:enable Metrics/ClassLength
end

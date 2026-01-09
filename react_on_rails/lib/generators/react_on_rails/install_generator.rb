# frozen_string_literal: true

require "rails/generators"
require "json"
require_relative "generator_helper"
require_relative "generator_messages"
require_relative "js_dependency_manager"

module ReactOnRails
  module Generators
    # rubocop:disable Metrics/ClassLength
    class InstallGenerator < Rails::Generators::Base
      include GeneratorHelper
      include JsDependencyManager

      # fetch USAGE file for details generator description
      source_root(File.expand_path(__dir__))

      # --redux
      class_option :redux,
                   type: :boolean,
                   default: false,
                   desc: "Install Redux package and Redux version of Hello World Example. Default: false",
                   aliases: "-R"

      # --typescript
      class_option :typescript,
                   type: :boolean,
                   default: false,
                   desc: "Generate TypeScript files and install TypeScript dependencies. Default: false",
                   aliases: "-T"

      # --rspack
      class_option :rspack,
                   type: :boolean,
                   default: false,
                   desc: "Use Rspack instead of Webpack as the bundler. Default: false"

      # --ignore-warnings
      class_option :ignore_warnings,
                   type: :boolean,
                   default: false,
                   desc: "Skip warnings. Default: false"

      # Removed: --skip-shakapacker-install (Shakapacker is now a required dependency)

      # Main generator entry point
      #
      # Sets up React on Rails in a Rails application by:
      # 1. Validating prerequisites
      # 2. Installing required packages
      # 3. Generating configuration files
      # 4. Setting up example components
      #
      # @note Validation Skipping: Sets ENV["REACT_ON_RAILS_SKIP_VALIDATION"] to prevent
      #   version validation from running during generator execution. The npm package
      #   isn't installed until midway through the generator, so validation would fail
      #   if run during Rails initialization. The ensure block guarantees cleanup even
      #   if the generator fails.
      def run_generators
        # Set environment variable to skip validation during generator run
        # This is inherited by all invoked generators and persists through Rails initialization
        # See lib/react_on_rails/engine.rb for the validation skip logic
        ENV["REACT_ON_RAILS_SKIP_VALIDATION"] = "true"

        if installation_prerequisites_met? || options.ignore_warnings?
          invoke_generators
          add_bin_scripts
          # Only add the post install message if not using Redux
          # Redux generator handles its own messages
          add_post_install_message unless options.redux?
        else
          error = <<~MSG.strip
            🚫 React on Rails generator prerequisites not met!

            Please resolve the issues listed above before continuing.
            All prerequisites must be satisfied for a successful installation.

            Use --ignore-warnings to bypass checks (not recommended).
          MSG
          GeneratorMessages.add_error(error)
        end
      ensure
        # Always clean up ENV variable, even if generator fails
        # CRITICAL: ENV cleanup must come first to ensure it executes even if
        # print_generator_messages raises an exception. This prevents ENV pollution
        # that could affect subsequent processes.
        ENV.delete("REACT_ON_RAILS_SKIP_VALIDATION")
        print_generator_messages
      end

      # Everything here is not run automatically b/c it's private

      private

      def print_generator_messages
        GeneratorMessages.messages.each { |message| puts message }
      end

      def invoke_generators
        ensure_shakapacker_installed
        if options.typescript?
          install_typescript_dependencies
          create_css_module_types
          create_typescript_config
        end
        invoke "react_on_rails:base", [],
               { typescript: options.typescript?, redux: options.redux?, rspack: options.rspack? }
        if options.redux?
          invoke "react_on_rails:react_with_redux", [], { typescript: options.typescript? }
        else
          invoke "react_on_rails:react_no_redux", [], { typescript: options.typescript? }
        end
        setup_react_dependencies
      end

      def setup_react_dependencies
        setup_js_dependencies
      end

      # NOTE: other requirements for existing files such as .gitignore or application.
      # js(.coffee) are not checked by this method, but instead produce warning messages
      # and allow the build to continue
      def installation_prerequisites_met?
        !(missing_node? || missing_package_manager? || ReactOnRails::GitUtils.uncommitted_changes?(GeneratorMessages))
      end

      def missing_node?
        node_missing = ReactOnRails::Utils.running_on_windows? ? `where node`.blank? : `which node`.blank?

        if node_missing
          error = <<~MSG.strip
            🚫 Node.js is required but not found on your system.

            Please install Node.js before continuing:
            • Download from: https://nodejs.org/en/
            • Recommended: Use a version manager like nvm, fnm, or volta
            • Minimum required version: Node.js 18+

            After installation, restart your terminal and try again.
          MSG
          GeneratorMessages.add_error(error)
          return true
        end

        # Check Node.js version if available
        check_node_version
        false
      end

      def check_node_version
        node_version = `node --version 2>/dev/null`.strip
        return if node_version.blank?

        # Extract major version number (e.g., "v18.17.0" -> 18)
        major_version = node_version[/v(\d+)/, 1]&.to_i
        return unless major_version

        return unless major_version < 18

        warning = <<~MSG.strip
          ⚠️  Node.js version #{node_version} detected.

          React on Rails recommends Node.js 18+ for best compatibility.
          You may experience issues with older versions.

          Consider upgrading: https://nodejs.org/en/
        MSG
        GeneratorMessages.add_warning(warning)
      end

      def ensure_shakapacker_installed
        return if shakapacker_configured?

        print_shakapacker_setup_banner
        ensure_shakapacker_in_gemfile
        install_shakapacker
        finalize_shakapacker_setup
      end

      # Checks whether "shakapacker" is explicitly declared in this project's Gemfile.
      # We only check the Gemfile text, not lockfile or dependencies, because
      # shakapacker might be present as a dependency of react_on_rails but not
      # properly configured for this specific Rails application.
      def shakapacker_in_gemfile?
        gem_name = "shakapacker"
        shakapacker_in_gemfile_text?(gem_name)
      end

      def add_bin_scripts
        # Copy bin scripts from templates
        template_bin_path = "#{__dir__}/templates/base/base/bin"
        directory template_bin_path, "bin"

        # Make these and only these files executable
        files_to_copy = []
        Dir.chdir(template_bin_path) do
          files_to_copy.concat(Dir.glob("*"))
        end
        files_to_become_executable = files_to_copy.map { |filename| "bin/#{filename}" }

        File.chmod(0o755, *files_to_become_executable)
      end

      def add_post_install_message
        # Determine what route will be created by the generator
        route = "hello_world" # This is the hardcoded route from base_generator.rb
        component_name = options.redux? ? "HelloWorldApp" : "HelloWorld"

        GeneratorMessages.add_info(GeneratorMessages.helpful_message_after_installation(
                                     component_name: component_name,
                                     route: route
                                   ))
      end

      def shakapacker_loaded_in_process?(gem_name)
        Gem.loaded_specs.key?(gem_name)
      end

      def shakapacker_in_lockfile?(gem_name)
        gemfile = ENV["BUNDLE_GEMFILE"] || "Gemfile"
        lockfile = File.join(File.dirname(gemfile), "Gemfile.lock")

        File.file?(lockfile) && File.foreach(lockfile).any? { |l| l.match?(/^\s{4}#{Regexp.escape(gem_name)}\s\(/) }
      end

      def shakapacker_in_bundler_specs?(gem_name)
        require "bundler"
        Bundler.load.specs.any? { |s| s.name == gem_name }
      rescue StandardError
        false
      end

      def shakapacker_in_gemfile_text?(gem_name)
        gemfile = ENV["BUNDLE_GEMFILE"] || "Gemfile"

        File.file?(gemfile) &&
          File.foreach(gemfile).any? { |l| l.match?(/^\s*gem\s+['"]#{Regexp.escape(gem_name)}['"]/) }
      end

      def cli_exists?(command)
        system("which #{command} > /dev/null 2>&1")
      end

      def shakapacker_binaries_exist?
        File.exist?("bin/shakapacker") && File.exist?("bin/shakapacker-dev-server")
      end

      def shakapacker_configured?
        # Check for essential shakapacker configuration files and binaries
        shakapacker_binaries_exist? &&
          File.exist?("config/shakapacker.yml") &&
          File.exist?("config/webpack/webpack.config.js")
      end

      def print_shakapacker_setup_banner
        puts Rainbow("\n#{'=' * 80}").cyan
        puts Rainbow("🔧 SHAKAPACKER SETUP").cyan.bold
        puts Rainbow("=" * 80).cyan
      end

      # DRY helper method for Bundler context switching with API compatibility
      # Supports both new (with_unbundled_env) and legacy (with_clean_env) Bundler APIs
      def with_unbundled_context(&block)
        if Bundler.respond_to?(:with_unbundled_env)
          Bundler.with_unbundled_env(&block)
        elsif Bundler.respond_to?(:with_clean_env)
          Bundler.with_clean_env(&block)
        else
          # Fallback if neither method is available (very old Bundler versions)
          yield
        end
      end

      def ensure_shakapacker_in_gemfile
        return if shakapacker_in_gemfile?

        puts Rainbow("📝 Adding Shakapacker to Gemfile...").yellow
        success = with_unbundled_context { system("bundle add shakapacker --strict") }
        return if success

        handle_shakapacker_gemfile_error
      end

      def install_shakapacker
        puts Rainbow("⚙️  Installing Shakapacker (required for webpack integration)...").yellow

        # First run bundle install to make shakapacker available
        puts Rainbow("📦 Running bundle install...").yellow
        bundle_success = with_unbundled_context { system("bundle install") }
        unless bundle_success
          handle_shakapacker_install_error
          return
        end

        # Then run the shakapacker installer
        success = with_unbundled_context { system("bundle exec rails shakapacker:install") }
        return if success

        handle_shakapacker_install_error
      end

      def finalize_shakapacker_setup
        puts Rainbow("✅ Shakapacker installed successfully!").green
        puts Rainbow("=" * 80).cyan
        puts Rainbow("🚀 CONTINUING WITH REACT ON RAILS SETUP").cyan.bold
        puts "#{Rainbow('=' * 80).cyan}\n"

        # Create marker file so base generator can avoid copying shakapacker.yml
        File.write(".shakapacker_just_installed", "")
      end

      def handle_shakapacker_gemfile_error
        error = <<~MSG.strip
          🚫 Failed to add Shakapacker to your Gemfile.

          This could be due to:
          • Bundle installation issues
          • Network connectivity problems
          • Gemfile permissions

          Please try manually:
              bundle add shakapacker --strict

          Then re-run: rails generate react_on_rails:install
        MSG
        GeneratorMessages.add_error(error)
        raise Thor::Error, error unless options.ignore_warnings?
      end

      def handle_shakapacker_install_error
        error = <<~MSG.strip
          🚫 Failed to install Shakapacker automatically.

          This could be due to:
          • Missing Node.js or npm/yarn
          • Network connectivity issues
          • Incomplete bundle installation
          • Missing write permissions

          Troubleshooting steps:
          1. Ensure Node.js is installed: node --version
          2. Run: bundle install
          3. Try manually: bundle exec rails shakapacker:install
          4. Check for error output above
          5. Re-run: rails generate react_on_rails:install

          Need help? Visit: https://github.com/shakacode/shakapacker/blob/main/docs/installation.md
        MSG
        GeneratorMessages.add_error(error)
        raise Thor::Error, error unless options.ignore_warnings?
      end

      def missing_package_manager?
        package_managers = %w[npm pnpm yarn bun]
        missing = package_managers.none? { |pm| cli_exists?(pm) }

        if missing
          error = <<~MSG.strip
            🚫 No JavaScript package manager found on your system.

            React on Rails requires a JavaScript package manager to install dependencies.
            Please install one of the following:

            • npm: Usually comes with Node.js (https://nodejs.org/en/)
            • yarn: npm install -g yarn (https://yarnpkg.com/)
            • pnpm: npm install -g pnpm (https://pnpm.io/)
            • bun: Install from https://bun.sh/

            After installation, restart your terminal and try again.
          MSG
          GeneratorMessages.add_error(error)
          return true
        end

        false
      end

      def install_typescript_dependencies
        puts Rainbow("📝 Installing TypeScript dependencies...").yellow
        # Delegate to shared module for consistent dependency management
        add_typescript_dependencies
      end

      def create_css_module_types
        puts Rainbow("📝 Creating CSS module type definitions...").yellow

        # Ensure the types directory exists
        FileUtils.mkdir_p("app/javascript/types")

        css_module_types_content = <<~TS.strip
          // TypeScript definitions for CSS modules
          declare module "*.module.css" {
            const classes: { [key: string]: string };
            export default classes;
          }

          declare module "*.module.scss" {
            const classes: { [key: string]: string };
            export default classes;
          }

          declare module "*.module.sass" {
            const classes: { [key: string]: string };
            export default classes;
          }
        TS

        File.write("app/javascript/types/css-modules.d.ts", css_module_types_content)
        puts Rainbow("✅ Created CSS module type definitions").green
      end

      def create_typescript_config
        if File.exist?("tsconfig.json")
          puts Rainbow("⚠️  tsconfig.json already exists, skipping creation").yellow
          return
        end

        tsconfig_content = {
          "compilerOptions" => {
            "target" => "es2018",
            "allowJs" => true,
            "skipLibCheck" => true,
            "strict" => true,
            "noUncheckedIndexedAccess" => true,
            "forceConsistentCasingInFileNames" => true,
            "noFallthroughCasesInSwitch" => true,
            "module" => "esnext",
            "moduleResolution" => "bundler",
            "resolveJsonModule" => true,
            "isolatedModules" => true,
            "noEmit" => true,
            "jsx" => "react-jsx"
          },
          "include" => [
            "app/javascript/**/*"
          ]
        }

        File.write("tsconfig.json", JSON.pretty_generate(tsconfig_content))
        puts Rainbow("✅ Created tsconfig.json").green
      end

      # Removed: Shakapacker auto-installation logic (now explicit dependency)

      # Removed: Shakapacker 8+ is now required as explicit dependency
      # rubocop:enable Metrics/ClassLength
    end
  end
end

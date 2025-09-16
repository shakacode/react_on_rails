# frozen_string_literal: true

require "rails/generators"
require_relative "generator_helper"
require_relative "generator_messages"

module ReactOnRails
  module Generators
    # rubocop:disable Metrics/ClassLength
    class InstallGenerator < Rails::Generators::Base
      include GeneratorHelper

      # fetch USAGE file for details generator description
      source_root(File.expand_path(__dir__))

      # --redux
      class_option :redux,
                   type: :boolean,
                   default: false,
                   desc: "Install Redux package and Redux version of Hello World Example. Default: false",
                   aliases: "-R"

      # --ignore-warnings
      class_option :ignore_warnings,
                   type: :boolean,
                   default: false,
                   desc: "Skip warnings. Default: false"

      # Removed: --skip-shakapacker-install (Shakapacker is now a required dependency)

      def run_generators
        if installation_prerequisites_met? || options.ignore_warnings?
          invoke_generators
          add_bin_scripts
          add_post_install_message
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
        print_generator_messages
      end

      # Everything here is not run automatically b/c it's private

      private

      def print_generator_messages
        GeneratorMessages.messages.each { |message| puts message }
      end

      def invoke_generators
        ensure_shakapacker_installed
        invoke "react_on_rails:base"
        if options.redux?
          invoke "react_on_rails:react_with_redux"
        else
          invoke "react_on_rails:react_no_redux"
        end
      end

      # NOTE: other requirements for existing files such as .gitignore or application.
      # js(.coffee) are not checked by this method, but instead produce warning messages
      # and allow the build to continue
      def installation_prerequisites_met?
        !(missing_node? || ReactOnRails::GitUtils.uncommitted_changes?(GeneratorMessages))
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
        return if File.exist?("bin/shakapacker") && File.exist?("bin/shakapacker-dev-server")

        puts Rainbow("\n#{'=' * 80}").cyan
        puts Rainbow("🔧 SHAKAPACKER SETUP").cyan.bold
        puts Rainbow("=" * 80).cyan

        # Add Shakapacker to Gemfile if not present
        unless shakapacker_in_gemfile?
          puts Rainbow("📝 Adding Shakapacker to Gemfile...").yellow
          success = system("bundle add shakapacker --strict")
          unless success
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
            exit(1)
          end
          puts Rainbow("✅ Shakapacker added to Gemfile successfully!").green
        end

        # Install Shakapacker
        puts Rainbow("⚙️  Installing Shakapacker (required for webpack integration)...").yellow
        success = system("./bin/rails shakapacker:install")

        unless success
          error = <<~MSG.strip
            🚫 Failed to install Shakapacker automatically.

            This could be due to:
            • Missing Node.js or npm/yarn
            • Network connectivity issues
            • Incomplete bundle installation
            • Missing write permissions

            Troubleshooting steps:
            1. Ensure Node.js is installed: node --version
            2. Try manually: ./bin/rails shakapacker:install
            3. Check for error output above
            4. Re-run: rails generate react_on_rails:install

            Need help? Visit: https://github.com/shakacode/shakapacker/blob/main/docs/installation.md
          MSG
          GeneratorMessages.add_error(error)
          exit(1)
        end

        puts Rainbow("✅ Shakapacker installed successfully!").green
        puts Rainbow("=" * 80).cyan
        puts Rainbow("🚀 CONTINUING WITH REACT ON RAILS SETUP").cyan.bold
        puts "#{Rainbow('=' * 80).cyan}\n"

        # Create marker file so base generator can avoid copying shakapacker.yml
        File.write(".shakapacker_just_installed", "")
      end

      # Checks whether "shakapacker" is present in the *current bundle*,
      # without loading it. Prioritizes Gemfile.lock (cheap + accurate),
      # then Bundler's resolved specs, and finally a light Gemfile scan.
      def shakapacker_in_gemfile?
        gem_name = "shakapacker"

        return true if shakapacker_loaded_in_process?(gem_name)
        return true if shakapacker_in_lockfile?(gem_name)
        return true if shakapacker_in_bundler_specs?(gem_name)
        return true if shakapacker_in_gemfile_text?(gem_name)

        false
      end

      def add_bin_scripts
        directory "#{__dir__}/bin", "bin"

        # Make these and only these files executable
        files_to_copy = []
        Dir.chdir("#{__dir__}/bin") do
          files_to_copy.concat(Dir.glob("*"))
        end
        files_to_become_executable = files_to_copy.map { |filename| "bin/#{filename}" }

        File.chmod(0o755, *files_to_become_executable)
      end

      def add_post_install_message
        GeneratorMessages.add_info(GeneratorMessages.helpful_message_after_installation)
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

      # Removed: Shakapacker auto-installation logic (now explicit dependency)

      # Removed: Shakapacker 8+ is now required as explicit dependency
    end
    # rubocop:enable Metrics/ClassLength
  end
end

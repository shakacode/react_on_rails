# frozen_string_literal: true

require "rails/generators"
require_relative "generator_helper"
require_relative "generator_messages"

module ReactOnRails
  module Generators
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
          error = "react_on_rails generator prerequisites not met!"
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
        return false unless ReactOnRails::Utils.running_on_windows? ? `where node`.blank? : `which node`.blank?

        error = "** nodejs is required. Please install it before continuing. https://nodejs.org/en/"
        GeneratorMessages.add_error(error)
        true
      end

      def ensure_shakapacker_installed
        return if File.exist?("bin/shakapacker") && File.exist?("bin/shakapacker-dev-server")

        puts Rainbow("\n" + "=" * 80).cyan
        puts Rainbow("🔧 SHAKAPACKER SETUP").cyan.bold
        puts Rainbow("=" * 80).cyan

        # Add Shakapacker to Gemfile if not present
        unless shakapacker_in_gemfile?
          puts Rainbow("📝 Adding Shakapacker to Gemfile...").yellow
          success = system("bundle add shakapacker --strict")
          unless success
            GeneratorMessages.add_error("Failed to add Shakapacker to Gemfile. Please run 'bundle add shakapacker' manually.")
            exit(1)
          end
          puts Rainbow("✅ Shakapacker added to Gemfile successfully!").green
        end

        # Install Shakapacker
        puts Rainbow("⚙️  Installing Shakapacker (required for webpack integration)...").yellow
        success = system("./bin/rails shakapacker:install")

        unless success
          error = <<~MSG.strip
            ** Failed to install Shakapacker automatically.

            Please run this command manually:

                ./bin/rails shakapacker:install

            Then re-run: rails generate react_on_rails:install
          MSG
          GeneratorMessages.add_error(error)
          exit(1)
        end

        puts Rainbow("✅ Shakapacker installed successfully!").green
        puts Rainbow("=" * 80).cyan
        puts Rainbow("🚀 CONTINUING WITH REACT ON RAILS SETUP").cyan.bold
        puts Rainbow("=" * 80).cyan + "\n"

        # Create marker file so base generator can avoid copying shakapacker.yml
        File.write(".shakapacker_just_installed", "")
      end

      def shakapacker_in_gemfile?
        return false unless File.exist?("Gemfile")

        gemfile_content = File.read("Gemfile")
        gemfile_content.match?(/gem\s+['"]shakapacker['"]/)
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

      # Removed: Shakapacker auto-installation logic (now explicit dependency)

      # Removed: Shakapacker 8+ is now required as explicit dependency
    end
  end
end

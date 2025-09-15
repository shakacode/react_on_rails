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
                   desc: "Install Redux gems and Redux version of Hello World Example. Default: false",
                   aliases: "-R"

      # --ignore-warnings
      class_option :ignore_warnings,
                   type: :boolean,
                   default: false,
                   desc: "Skip warnings. Default: false"

      # --skip-shakapacker-install
      class_option :skip_shakapacker_install,
                   type: :boolean,
                   default: false,
                   desc: "Skip automatic Shakapacker installation. Default: false"

      def run_generators
        if installation_prerequisites_met? || options.ignore_warnings?
          return if !options.skip_shakapacker_install? && !ensure_shakapacker_installed

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
        invoke "react_on_rails:base"
        if options.redux?
          invoke "react_on_rails:react_with_redux"
        else
          invoke "react_on_rails:react_no_redux"
        end

        invoke "react_on_rails:adapt_for_older_shakapacker" unless using_shakapacker_7_or_above?
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

      def ensure_shakapacker_installed
        return true if shakapacker_installed?

        GeneratorMessages.add_info(<<~MSG.strip)
          Shakapacker gem not found in your Gemfile.
          React on Rails requires Shakapacker for webpack integration.
          Adding 'shakapacker' gem to your Gemfile and running installation...
        MSG

        added = system("bundle", "add", "shakapacker")
        unless added
          GeneratorMessages.add_error(<<~MSG.strip)
            Failed to add Shakapacker to your Gemfile.
            Please run 'bundle add shakapacker' manually and re-run the generator.
          MSG
          return false
        end

        installed = system("bundle", "exec", "rails", "shakapacker:install")
        unless installed
          GeneratorMessages.add_error(<<~MSG.strip)
            Failed to install Shakapacker automatically.
            Please run 'bundle exec rails shakapacker:install' manually.
          MSG
          return false
        end

        GeneratorMessages.add_info("Shakapacker installed successfully!")
        true
      end

      def shakapacker_installed?
        Gem::Specification.find_by_name("shakapacker")
        true
      rescue Gem::LoadError
        false
      end

      def using_shakapacker_7_or_above?
        shakapacker_gem = Gem::Specification.find_by_name("shakapacker")
        shakapacker_gem.version.segments.first >= 7
      rescue Gem::MissingSpecError
        # In case using Webpacker
        false
      end
    end
  end
end

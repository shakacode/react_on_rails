# frozen_string_literal: true

require "rails/generators"
require "react_on_rails/agent_guardrails"
require_relative "generator_helper"
require_relative "generator_messages"
require_relative "js_dependency_manager"
require_relative "rsc_setup"

module ReactOnRails
  module Generators
    class RscGenerator < Rails::Generators::Base
      include GeneratorHelper
      include JsDependencyManager
      include RscSetup

      source_root File.expand_path(__dir__)

      def self.usage_path
        File.expand_path("rsc/USAGE", __dir__)
      end

      class_option :typescript,
                   type: :boolean,
                   default: false,
                   desc: "Generate TypeScript files",
                   aliases: "-T"

      # Hidden option for when invoked from install_generator
      # Skips prerequisite checks and message printing (parent handles both)
      class_option :invoked_by_install,
                   type: :boolean,
                   default: false,
                   hide: true

      class_option :new_app,
                   type: :boolean,
                   default: false,
                   hide: true

      class_option :redux,
                   type: :boolean,
                   default: false,
                   hide: true

      class_option :tailwind,
                   type: :boolean,
                   default: false,
                   hide: true

      def run_generator
        # When invoked by install_generator, skip prerequisites (parent already validated)
        if options[:invoked_by_install] || prerequisites_met?
          warn_about_react_version_for_rsc(force: true)
          setup_rsc
          add_rsc_npm_dependencies
          install_agent_guardrails
          print_success_message unless options[:invoked_by_install]
        else
          GeneratorMessages.add_error(<<~MSG.strip)
            🚫 React on Rails RSC generator prerequisites not met!

            Please resolve the issues listed above before continuing.
          MSG
        end
      ensure
        print_generator_messages unless options[:invoked_by_install]
      end

      private

      def prerequisites_met?
        !missing_pro_installation? && !unsupported_standalone_tailwind?
      end

      def unsupported_standalone_tailwind?
        return false unless use_tailwind?

        GeneratorMessages.add_error(<<~MSG.strip)
          🚫 The standalone react_on_rails:rsc generator does not support --tailwind.

          Tailwind setup requires the base React on Rails installer so it can create the
          react_on_rails_tailwind pack, stylesheet, dependencies, and webpack/Rspack config.

          Use the install generator for RSC + Tailwind setup:

            rails generate react_on_rails:install --rsc --tailwind

          If this app already has RSC and you want to add Tailwind later, run the install
          generator with --tailwind so the base Tailwind files are installed before RSC
          layout wiring is reused.
        MSG
        true
      end

      def missing_pro_installation?
        return false if pro_installed?

        GeneratorMessages.add_error(<<~MSG.strip)
          🚫 React on Rails Pro is not installed in this application.

          RSC requires Pro. Please run the Pro generator first:

            rails g react_on_rails:pro

          Then re-run this generator to add RSC features.
        MSG
        true
      end

      def pro_installed?
        File.exist?(File.join(destination_root, "config/initializers/react_on_rails_pro.rb"))
      end

      def use_rsc?
        true
      end

      def add_rsc_npm_dependencies
        say "📝 Adding RSC npm dependencies...", :yellow
        add_rsc_dependencies
        say "✅ RSC npm dependencies added", :green
      end

      def install_agent_guardrails
        if options[:pretend]
          say_status :pretend, ".claude/ (RSC agent guardrails)", :yellow
          return
        end

        say "🛡️  Installing RSC agent guardrails (rsc-app-safety skill + advisory hook)...", :yellow
        ReactOnRails::AgentGuardrails.install(destination_root, skip_existing: options[:skip]).each do |action|
          say "   #{action}"
        end
        say "✅ RSC agent guardrails installed", :green
      rescue ReactOnRails::AgentGuardrails::Error => e
        say "⚠️  Skipped RSC agent guardrails: #{e.message}", :yellow
      end

      def print_success_message
        GeneratorMessages.add_info(<<~MSG)
          Next steps:
          1. Start the app: bin/dev (or foreman start -f Procfile.dev)
          2. Visit http://localhost:3000/hello_server to see RSC in action
          3. The RSC bundle watcher will compile server components

          Documentation: https://reactonrails.com/docs/pro/react-server-components/
        MSG
      end
    end
  end
end

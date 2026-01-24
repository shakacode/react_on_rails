# frozen_string_literal: true

require "rails/generators"
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

      class_option :typescript,
                   type: :boolean,
                   default: false,
                   desc: "Generate TypeScript files",
                   aliases: "-T"

      desc "Add React Server Components to an existing React on Rails Pro application"

      def run_generator
        if prerequisites_met?
          warn_about_react_version_for_rsc(force: true)
          setup_rsc
          add_rsc_npm_dependencies
          print_success_message
        else
          GeneratorMessages.add_error(<<~MSG.strip)
            🚫 React on Rails RSC generator prerequisites not met!

            Please resolve the issues listed above before continuing.
          MSG
        end
      ensure
        print_generator_messages
      end

      private

      def prerequisites_met?
        !missing_pro_installation?
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
        puts Rainbow("📝 Adding RSC npm dependencies...").yellow
        add_rsc_dependencies
        puts Rainbow("✅ RSC npm dependencies added").green
      end

      def print_success_message
        GeneratorMessages.add_info(<<~MSG)
          ✅ React Server Components setup complete!

          Next steps:
          1. Start the app: bin/dev (or foreman start -f Procfile.dev)
          2. Visit http://localhost:3000/hello_server to see RSC in action
          3. The RSC bundle watcher will compile server components

          Documentation: https://www.shakacode.com/react-on-rails-pro/docs/rsc/
        MSG
      end
    end
  end
end

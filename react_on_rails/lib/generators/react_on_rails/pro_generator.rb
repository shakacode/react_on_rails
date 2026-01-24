# frozen_string_literal: true

require "rails/generators"
require_relative "generator_helper"
require_relative "generator_messages"
require_relative "js_dependency_manager"
require_relative "pro_setup"

module ReactOnRails
  module Generators
    class ProGenerator < Rails::Generators::Base
      include GeneratorHelper
      include JsDependencyManager
      include ProSetup

      source_root File.expand_path("templates", __dir__)

      desc "Add React on Rails Pro to an existing React on Rails application"

      def run_generator
        if prerequisites_met?
          setup_pro
          add_pro_npm_dependencies
          print_success_message
        else
          GeneratorMessages.add_error(<<~MSG.strip)
            🚫 React on Rails Pro generator prerequisites not met!

            Please resolve the issues listed above before continuing.
          MSG
        end
      ensure
        print_generator_messages
      end

      private

      def prerequisites_met?
        !(missing_base_installation? || pro_gem_missing?)
      end

      def missing_base_installation?
        return false if base_react_on_rails_installed?

        GeneratorMessages.add_error(<<~MSG.strip)
          🚫 React on Rails is not installed in this application.

          This generator adds Pro features to an existing React on Rails app.
          Please run the base installer first:

            rails g react_on_rails:install

          Then re-run this generator to add Pro features.
        MSG
        true
      end

      def base_react_on_rails_installed?
        File.exist?(File.join(destination_root, "config/initializers/react_on_rails.rb"))
      end

      def add_pro_npm_dependencies
        puts Rainbow("📝 Adding Pro npm dependencies...").yellow
        add_pro_dependencies
        puts Rainbow("✅ Pro npm dependencies added").green
      end

      def print_success_message
        GeneratorMessages.add_info(<<~MSG)
          ✅ React on Rails Pro setup complete!

          Next steps:
          1. Set your license: export REACT_ON_RAILS_PRO_LICENSE=your_token
          2. Start the app: bin/dev (or foreman start -f Procfile.dev)
          3. The Node Renderer will start on port 3800

          Documentation: https://www.shakacode.com/react-on-rails-pro/docs/
        MSG
      end
    end
  end
end

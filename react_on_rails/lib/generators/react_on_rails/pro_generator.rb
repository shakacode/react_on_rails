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

      source_root File.expand_path(__dir__)

      def self.usage_path
        File.expand_path("pro/USAGE", __dir__)
      end

      # Hidden option for when invoked from install_generator
      # Skips prerequisite checks and message printing (parent handles both)
      class_option :invoked_by_install,
                   type: :boolean,
                   default: false,
                   hide: true

      def run_generator
        # When invoked by install_generator, skip prerequisites (parent already validated)
        if options[:invoked_by_install] || prerequisites_met?
          swap_base_gem_for_pro_in_gemfile unless options[:invoked_by_install]
          setup_pro
          add_pro_npm_dependencies
          update_imports_to_pro_package unless options[:invoked_by_install]
          print_success_message unless options[:invoked_by_install]
        else
          GeneratorMessages.add_error(<<~MSG.strip)
            🚫 React on Rails Pro generator prerequisites not met!

            Please resolve the issues listed above before continuing.
          MSG
        end
      ensure
        print_generator_messages unless options[:invoked_by_install]
      end

      private

      def prerequisites_met?
        !(missing_base_installation? || missing_pro_gem?(force: true))
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
        say "📝 Adding Pro npm dependencies...", :yellow
        add_pro_dependencies
        say "✅ Pro npm dependencies added", :green
      end

      def swap_base_gem_for_pro_in_gemfile
        gemfile_path = File.join(destination_root, "Gemfile")
        return unless File.exist?(gemfile_path)

        gemfile_content = File.read(gemfile_path)
        updated_content = gemfile_content.gsub(
          /^\s*gem\s+["']react_on_rails["'][^\n]*$/,
          "gem 'react_on_rails_pro', '#{recommended_pro_gem_version}'"
        )
        return if updated_content == gemfile_content

        File.write(gemfile_path, updated_content)
        say "✅ Replaced react_on_rails with react_on_rails_pro in Gemfile", :green
        bundle_install_after_gem_swap
      end

      def bundle_install_after_gem_swap
        say "📦 Running bundle install after Gemfile update...", :yellow
        install_succeeded = Dir.chdir(destination_root) do
          Bundler.with_unbundled_env { system("bundle install") }
        end

        return if install_succeeded

        GeneratorMessages.add_warning(<<~MSG.strip)
          ⚠️  Automatic bundle install failed after swapping Gemfile entries.

          Please run manually:
            bundle install
        MSG
      rescue StandardError => e
        GeneratorMessages.add_warning(<<~MSG.strip)
          ⚠️  Could not run automatic bundle install: #{e.message}

          Please run manually:
            bundle install
        MSG
      end

      def update_imports_to_pro_package
        files = js_files_for_import_update
        updated_files = files.count do |file|
          content = File.read(file)
          updated_content = content.gsub(/react-on-rails(?!-pro)/, "react-on-rails-pro")
          next false if updated_content == content

          File.write(file, updated_content)
          true
        end

        return if updated_files.zero?

        say "✅ Updated react-on-rails imports in #{updated_files} file(s)", :green
      end

      def js_files_for_import_update
        js_extensions = %w[js jsx ts tsx mjs cjs].join(",")
        %w[app/javascript client].flat_map do |root|
          root_path = File.join(destination_root, root)
          next [] unless Dir.exist?(root_path)

          Dir.glob(File.join(root_path, "**", "*.{#{js_extensions}}"))
        end
      end

      def print_success_message
        route = if File.exist?(File.join(destination_root, "app/controllers/hello_server_controller.rb"))
                  "hello_server"
                else
                  "hello_world"
                end

        GeneratorMessages.add_info(<<~MSG)
          Next steps:
          1. Set your license: export REACT_ON_RAILS_PRO_LICENSE=your_token
          2. Start the app: bin/dev (or foreman start -f Procfile.dev)
          3. Visit http://localhost:3000/#{route}
          4. The Node Renderer will start on port 3800

          Documentation: https://reactonrails.com/docs/pro/
        MSG
      end
    end
  end
end

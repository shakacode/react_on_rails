# frozen_string_literal: true

# You can replace this implementation with your own for use by the
# ReactOnRails::TestHelper.ensure_assets_compiled helper
module ReactOnRails
  module TestHelper
    class WebpackAssetsCompiler
      TESTING_DOCS_URL = "https://github.com/shakacode/react_on_rails/blob/master/" \
                         "docs/oss/building-features/dev-server-and-testing.md"

      def compile_assets
        if ReactOnRails.configuration.build_test_command.blank?
          puts Rainbow(missing_build_test_command_message).red
          exit!(1)
        end

        puts "\nBuilding Webpack assets..."

        cmd = ReactOnRails::Utils.prepend_cd_node_modules_directory(
          ReactOnRails.configuration.build_test_command
        )

        ReactOnRails::Utils.invoke_and_exit_if_failed(cmd, compilation_failed_message)

        puts "Completed building Webpack assets."
      end

      private

      def missing_build_test_command_message
        <<~MSG
          React on Rails: build_test_command is not configured.

          You are using the React on Rails test helper (configure_rspec_to_compile_assets
          or ensure_assets_compiled), but config.build_test_command is not set.

          To fix this, either:
            1. Set config.build_test_command in config/initializers/react_on_rails.rb:
                 config.build_test_command = "RAILS_ENV=test bin/shakapacker"
            2. Or remove the TestHelper call and use compile: true in config/shakapacker.yml

          For how dev server modes interact with tests, see:
            #{TESTING_DOCS_URL}
          Run 'bin/dev --help' for available development server modes.
          Run 'bundle exec rake react_on_rails:doctor' to diagnose your setup.

          Aborting test run.
        MSG
      end

      def compilation_failed_message
        <<~MSG
          React on Rails: Error building webpack assets!

          The build_test_command failed. This means test assets could not be compiled.

          Quick alternatives to get unblocked:
            • Run 'bin/dev static' in another terminal (assets auto-reuse for tests)
            • Run 'bin/dev test-watch' to keep test assets fresh in the background
            • Run 'RAILS_ENV=test bin/shakapacker' manually to compile once

          For full details: #{TESTING_DOCS_URL}
          Run 'bin/dev --help' for development server modes.
        MSG
      end
    end
  end
end

# frozen_string_literal: true

# You can replace this implementation with your own for use by the
# ReactOnRails::TestHelper.ensure_assets_compiled helper
module ReactOnRails
  module TestHelper
    class WebpackAssetsCompiler
      def compile_assets
        if ReactOnRails.configuration.build_test_command.blank?
          msg = <<~MSG
            You are using the React on Rails test helper. 
            Either you used:
              ReactOnRails::TestHelper.configure_rspec_to_compile_assets or
              ReactOnRails::TestHelper.ensure_assets_compiled
            but you did not specify the config.build_test_command

            React on Rails is aborting your test run

            If you wish to use the config/webpacker.yml compile option for tests
            them remove your call to the ReactOnRails test helper.
          MSG
          puts Rainbow(msg).red
          exit!(1)
        end

        puts "\nBuilding Webpack assets..."

        cmd = ReactOnRails::Utils.prepend_cd_node_modules_directory(
          ReactOnRails.configuration.build_test_command
        )

        ReactOnRails::Utils.invoke_and_exit_if_failed(cmd, "Error in building webpack assets!")

        puts "Completed building Webpack assets."
      end
    end
  end
end

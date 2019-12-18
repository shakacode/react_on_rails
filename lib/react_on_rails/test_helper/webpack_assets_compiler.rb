# frozen_string_literal: true

# You can replace this implementation with your own for use by the
# ReactOnRails::TestHelper.ensure_assets_compiled helper
module ReactOnRails
  module TestHelper
    class WebpackAssetsCompiler
      def compile_assets
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

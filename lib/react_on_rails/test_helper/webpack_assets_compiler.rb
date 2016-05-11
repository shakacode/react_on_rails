# You can replace this implementation with your own for use by the
# ReactOnRails::TestHelper.ensure_assets_compiled helper
module ReactOnRails
  module TestHelper
    class WebpackAssetsCompiler
      def compile_assets
        puts "\nBuilding Webpack assets..."

        build_output = `cd client && #{ReactOnRails.configuration.npm_build_test_command}`

        raise "Error in building assets!\n#{build_output}" unless Utils.last_process_completed_successfully?

        puts "Completed building Webpack assets."
      end
    end
  end
end

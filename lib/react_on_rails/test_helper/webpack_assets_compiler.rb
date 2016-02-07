# You can replace this implementation with your own for use by the
# ReactOnRails::TestHelper.ensure_assets_compiled helper
module ReactOnRails
  module TestHelper
    class WebpackAssetsCompiler
      def compile
        compile_type(:client)
        compile_type(:server) if Utils.server_rendering_is_enabled?
      end

      private

      def compile_type(type)
        unless @printed_msg
          puts <<-MSG
If you are frequently running tests, you can run webpack in watch mode to speed up this process.
See the official documentation:
https://github.com/shakacode/react_on_rails/blob/master/docs/additional_reading/rspec_configuration.md
          MSG
          @printed_msg = true
        end

        puts "\nBuilding Webpack #{type}-rendering assets..."

        build_output = `cd client && npm run build:#{type}`

        fail "Error in building assets!\n#{build_output}" unless Utils.last_process_completed_successfully?

        puts "Completed building Webpack #{type}-rendering assets."
      end
    end
  end
end

# You can replace this implementation with your own for use by the
# ReactOnRails::TestHelper.ensure_assets_compiled helper
module ReactOnRails
  module TestHelper
    class WebpackAssetsCompiler
      def compile_as_necessary(stale_files)
        compile_client(stale_files)
        compile_server(stale_files)
      end

      def compile_client(stale_files)
        compile_type(:client) if needs_client_compile?(stale_files)
      end

      def compile_server(stale_files)
        compile_type(:server) if needs_server_compile?(stale_files)
      end

      private

      def compile_type(type)
        puts "\nBuilding Webpack #{type}-rendering assets..."

        build_output = `cd client && npm run build:#{type}`

        raise "Error in building assets!\n#{build_output}" unless Utils.last_process_completed_successfully?

        puts "Completed building Webpack #{type}-rendering assets."
      end

      def needs_client_compile?(stale_files)
        !stale_files.all? { |name| name.include?("server") }
      end

      def needs_server_compile?(stale_files)
        return false unless Utils.server_rendering_is_enabled?
        stale_files.any? { |name| name.include?("server") }
      end
    end
  end
end

module ReactOnRails
  class WebpackAssetsCompiler
    def compile
      compile_type(:client)
      compile_type(:server) if Utils.server_rendering_is_enabled?
    end

    private

    def compile_type(type)
      puts "\n\nBuilding Webpack #{type}-rendering assets..."
      build_output = `cd client && npm run build:#{type}`

      fail "Error in building assets!\n#{build_output}" unless Utils.last_process_completed_successfully?

      puts "Webpack #{type}-rendering assets built. If you are frequently running\n"\
           "tests, you can run webpack in watch mode to speed up this process.\n"\
           "See the official documentation:\n"\
           "https://github.com/shakacode/react_on_rails/blob/master/docs/additional_reading/rspec_configuration.md\n\n"
    end
  end
end

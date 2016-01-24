module ReactOnRails
  module EnsureAssetsCompiled
    def self.check_built_assets
      return if @checks_complete
      puts "Checking for existing webpack bundles before running tests."
      build_assets_for_type("client")
      build_assets_for_type("server") if ReactOnRails.configuration.server_bundle_js_file.present?
      @checks_complete = true
    end

    def self.build_assets_for_type(type)
      unless running_webpack_watch?(type)
        puts "Building Webpack #{type}-rendering assets..."
        build_output = `cd client && npm run build:#{type}`
        if build_output =~ /error/i
          fail "Error in building assets!\n#{build_output}"
        else
          puts "Webpack #{type}-rendering assets built."
        end
      end
    end

    def self.running_webpack_watch?(type)
      running = `pgrep -fl '\\-w \\-\\-config webpack\\.#{type}\\.rails\\.build\\.config\\.js'`
      if running.present?
        puts "Webpack is running for #{type}-rendering assets, skipping rebuild => #{running.ai}"
        return true
      end
    end
  end
end

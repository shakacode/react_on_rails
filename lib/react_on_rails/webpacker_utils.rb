module ReactOnRails
  module WebpackerUtils
    def self.using_webpacker?
      ReactOnRails::Utils.gem_available?("webpacker")
    end

    def self.bundle_js_file_path_from_webpacker(bundle_name)
      # Note Webpacker 3.4.3 manifest lookup is inside of the public_output_path
      # [2] (pry) ReactOnRails::WebpackerUtils: 0> Webpacker.manifest.lookup("app-bundle.js")
      # "/webpack/development/app-bundle-c1d2b6ab73dffa7d9c0e.js"
      hashed_bundle_name = Webpacker.manifest.lookup!(bundle_name)

      if Webpacker.dev_server.running?
        "#{Webpacker.dev_server.protocol}://#{Webpacker.dev_server.host_with_port}#{hashed_bundle_name}"
      else
        # Next line will throw if the file or manifest does not exist
        File.expand_path(File.join("public", hashed_bundle_name)).to_s
      end
    end

    def self.webpacker_source_path
      Webpacker.config.source_path
    end

    def self.webpacker_public_output_path
      # Webpacker has the full absolute path of webpacker output files in a pathname
      Webpacker.config.public_output_path.to_s
    end

    def self.manifest_exists?
      Webpacker.config.public_manifest_path.exist?
    end

    def self.check_manifest_not_cached
      return unless using_webpacker? && Webpacker.config.cache_manifest?
      msg = <<-MSG.strip_heredoc
          ERROR: you have enabled cache_manifest in the #{Rails.env} env when using the
          ReactOnRails::TestHelper.configure_rspec_to_compile_assets helper
          To fix this: edit your config/webpacker.yml file and set cache_manifest to false for test.
      MSG
      puts wrap_message(msg)
      exit!
    end
  end
end

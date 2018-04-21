module ReactOnRails
  module WebpackerUtils
    def self.using_webpacker?
      ActionController::Base.helpers.respond_to?(:asset_pack_path)
    end

    def self.bundle_js_file_path_from_webpacker(bundle_name)
      possible_result = Webpacker.manifest.lookup(bundle_name)
      hashed_bundle_name = possible_result.nil? ? Webpacker.manifest.lookup!(bundle_name) : possible_result
      if Webpacker.dev_server.running?
        result = "#{Webpacker.dev_server.protocol}://#{Webpacker.dev_server.host_with_port}#{hashed_bundle_name}"
        result
      else
        # Next line will throw if the file or manifest does not exist
        Rails.root.join(File.join("public", hashed_bundle_name)).to_s
      end
    end

    def self.webpacker_source_path
      Webpacker.config.source_path
    end

    def self.webpacker_public_output_path
      Webpacker.config.public_output_path
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

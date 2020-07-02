# frozen_string_literal: true

module ReactOnRails
  module WebpackerUtils
    def self.using_webpacker?
      ReactOnRails::Utils.gem_available?("webpacker")
    end

    def self.webpacker_webpack_production_config_exists?
      webpacker_webpack_config_abs_path = File.join(Rails.root,
                                                    "config/webpack/production.js")
      File.exist?(webpacker_webpack_config_abs_path)
    end

    def self.dev_server_running?
      return false unless using_webpacker?

      Webpacker.dev_server.running?
    end

    # This returns either a URL for the webpack-dev-server, non-server bundle or
    # the hashed server bundle if using the same bundle for the client.
    # Otherwise returns a file path.
    def self.bundle_js_uri_from_webpacker(bundle_name)
      # Note Webpacker 3.4.3 manifest lookup is inside of the public_output_path
      # [2] (pry) ReactOnRails::WebpackerUtils: 0> Webpacker.manifest.lookup("app-bundle.js")
      # "/webpack/development/app-bundle-c1d2b6ab73dffa7d9c0e.js"
      # Next line will throw if the file or manifest does not exist
      hashed_bundle_name = Webpacker.manifest.lookup!(bundle_name)

      # support for hashing the server-bundle and having that built
      # by a webpack watch process and not served by the webpack-dev-server, then we
      # need an extra config value "same_bundle_for_client_and_server" where a value of false
      # would mean that the bundle is created by a separate webpack watch process.
      is_server_bundle = bundle_name == ReactOnRails.configuration.server_bundle_js_file

      if Webpacker.dev_server.running? && (!is_server_bundle ||
        ReactOnRails.configuration.same_bundle_for_client_and_server)
        "#{Webpacker.dev_server.protocol}://#{Webpacker.dev_server.host_with_port}#{hashed_bundle_name}"
      else
        File.expand_path(File.join("public", hashed_bundle_name)).to_s
      end
    end

    def self.webpacker_source_path
      Webpacker.config.source_path
    end

    def self.webpacker_public_output_path
      # Webpacker has the full absolute path of webpacker output files in a Pathname
      Webpacker.config.public_output_path.to_s
    end

    def self.manifest_exists?
      Webpacker.config.public_manifest_path.exist?
    end

    def self.webpacker_source_path_explicit?
      # WARNING: Calling private method `data` on Webpacker::Configuration, lib/webpacker/configuration.rb
      config_webpacker_yml = Webpacker.config.send(:data)
      config_webpacker_yml[:source_path].present?
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

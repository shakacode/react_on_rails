# frozen_string_literal: true

module ReactOnRails
  module WebpackerUtils
    def self.using_webpacker?
      return @using_webpacker if defined?(@using_webpacker)

      @using_webpacker = ReactOnRails::Utils.gem_available?("webpacker") ||
                         ReactOnRails::Utils.gem_available?("shakapacker")
    end

    def self.dev_server_running?
      return false unless using_webpacker?

      Webpacker.dev_server.running?
    end

    def self.shakapacker_version
      return nil unless ReactOnRails::Utils.gem_available?("shakapacker")

      @shakapacker_version ||= Gem.loaded_specs["shakapacker"].version.to_s
    end

    def self.shakapacker_version_as_array
      match = shakapacker_version.match(ReactOnRails::VersionChecker::MAJOR_MINOR_PATCH_VERSION_REGEX)

      @shakapacker_version_as_array = [match[1].to_i, match[2].to_i, match[3].to_i]
    end

    def self.shackapacker_version_requirement_met?(required_version)
      req_ver = semver_to_string(required_version)

      Gem::Version.new(shakapacker_version) >= Gem::Version.new(req_ver)
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

      # Support for hashing the server-bundle and having that built
      # the webpack-dev-server is provided by the config value
      # "same_bundle_for_client_and_server" where a value of true
      # would mean that the bundle is created by the webpack-dev-server
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

    def self.webpacker_source_entry_path
      Webpacker.config.source_entry_path
    end

    def self.nested_entries?
      Webpacker.config.nested_entries?
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

    def self.webpack_assets_status_checker
      source_path = ReactOnRails::Utils.source_path
      generated_assets_full_path = ReactOnRails::Utils.generated_assets_full_path
      webpack_generated_files = ReactOnRails.configuration.webpack_generated_files

      @webpack_assets_status_checker ||= ReactOnRails::TestHelper::WebpackAssetsStatusChecker.new(
        source_path: source_path,
        generated_assets_full_path: generated_assets_full_path,
        webpack_generated_files: webpack_generated_files
      )
    end

    def self.raise_nested_entries_disabled
      msg = <<~MSG
        **ERROR** ReactOnRails: `nested_entries` is configured to be disabled in shakapacker. Please update \
        webpacker.yml to enable nested entries. for more information read
        https://www.shakacode.com/react-on-rails/docs/guides/file-system-based-automated-bundle-generation.md#enable-nested_entries-for-shakapacker
      MSG

      raise ReactOnRails::Error, msg
    end

    def self.raise_shakapacker_version_incompatible_for_autobundling
      msg = <<~MSG
        **ERROR** ReactOnRails: Please upgrade Shakapacker to version #{ReactOnRails::WebpackerUtils.semver_to_string(ReactOnRails::PacksGenerator::MINIMUM_SHAKAPACKER_VERSION)} or \
        above to use the automated bundle generation feature. The currently installed version is \
        #{ReactOnRails::WebpackerUtils.semver_to_string(ReactOnRails::WebpackerUtils.shakapacker_version_as_array)}.
      MSG

      raise ReactOnRails::Error, msg
    end

    def self.raise_shakapacker_not_installed
      msg = <<~MSG
        **ERROR** ReactOnRails: Missing Shakapacker gem. Please upgrade to use Shakapacker \
        #{ReactOnRails::WebpackerUtils.semver_to_string(minimum_required_shakapacker_version)} or above to use the \
        automated bundle generation feature.
      MSG

      raise ReactOnRails::Error, msg
    end

    def self.semver_to_string(ary)
      "#{ary[0]}.#{ary[1]}.#{ary[2]}"
    end
  end
end

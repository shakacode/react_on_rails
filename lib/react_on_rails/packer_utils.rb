# frozen_string_literal: true

module ReactOnRails
  module PackerUtils
    def self.dev_server_running?
      Shakapacker.dev_server.running?
    end

    def self.dev_server_url
      "#{Shakapacker.dev_server.protocol}://#{Shakapacker.dev_server.host_with_port}"
    end

    def self.shakapacker_version
      return @shakapacker_version if defined?(@shakapacker_version)

      @shakapacker_version = Gem.loaded_specs["shakapacker"].version.to_s
    end

    def self.shakapacker_version_as_array
      return @shakapacker_version_as_array if defined?(@shakapacker_version_as_array)

      match = shakapacker_version.match(ReactOnRails::VersionChecker::VERSION_PARTS_REGEX)

      # match[4] is the pre-release version, not normally a number but something like "beta.1" or `nil`
      @shakapacker_version_as_array = [match[1].to_i, match[2].to_i, match[3].to_i, match[4]].compact
    end

    def self.shakapacker_version_requirement_met?(required_version)
      Gem::Version.new(shakapacker_version) >= Gem::Version.new(required_version)
    end

    def self.supports_autobundling?
      shakapacker_version_requirement_met?(ReactOnRails::PacksGenerator::MINIMUM_SHAKAPACKER_VERSION)
    end

    def self.supports_async_loading?
      shakapacker_version_requirement_met?("8.2.0")
    end

    # This returns either a URL for the webpack-dev-server, non-server bundle or
    # the hashed server bundle if using the same bundle for the client.
    # Otherwise returns a file path.
    def self.bundle_js_uri_from_packer(bundle_name)
      hashed_bundle_name = Shakapacker.manifest.lookup!(bundle_name)

      # Support for hashing the server-bundle and having that built
      # the webpack-dev-server is provided by the config value
      # "same_bundle_for_client_and_server" where a value of true
      # would mean that the bundle is created by the webpack-dev-server
      is_bundle_running_on_server = (bundle_name == ReactOnRails.configuration.server_bundle_js_file) ||
                                    (bundle_name == ReactOnRails.configuration.rsc_bundle_js_file)

      if Shakapacker.dev_server.running? && (!is_bundle_running_on_server ||
        ReactOnRails.configuration.same_bundle_for_client_and_server)
        "#{dev_server_url}#{hashed_bundle_name}"
      else
        File.expand_path(File.join("public", hashed_bundle_name)).to_s
      end
    end

    def self.public_output_uri_path
      "#{Shakapacker.config.public_output_path.relative_path_from(Shakapacker.config.public_path)}/"
    end

    # The function doesn't ensure that the asset exists.
    # - It just returns url to the asset if dev server is running
    # - Otherwise it returns file path to the asset
    def self.asset_uri_from_packer(asset_name)
      if dev_server_running?
        "#{dev_server_url}/#{public_output_uri_path}#{asset_name}"
      else
        File.join(packer_public_output_path, asset_name).to_s
      end
    end

    def self.precompile?
      ::Shakapacker.config.shakapacker_precompile?
    end

    def self.packer_source_path
      Shakapacker.config.source_path
    end

    def self.packer_source_entry_path
      Shakapacker.config.source_entry_path
    end

    def self.nested_entries?
      Shakapacker.config.nested_entries?
    end

    def self.packer_public_output_path
      Shakapacker.config.public_output_path.to_s
    end

    def self.manifest_exists?
      Shakapacker.config.public_manifest_path.exist?
    end

    def self.packer_source_path_explicit?
      Shakapacker.config.send(:data)[:source_path].present?
    end

    def self.check_manifest_not_cached
      return unless Shakapacker.config.cache_manifest?

      msg = <<-MSG.strip_heredoc
          ERROR: you have enabled cache_manifest in the #{Rails.env} env when using the
          ReactOnRails::TestHelper.configure_rspec_to_compile_assets helper
          To fix this: edit your config/shakapacker.yml file and set cache_manifest to false for test.
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
        config/shakapacker.yml to enable nested entries. for more information read
        https://www.shakacode.com/react-on-rails/docs/guides/file-system-based-automated-bundle-generation.md#enable-nested_entries-for-shakapacker
      MSG

      raise ReactOnRails::Error, msg
    end

    def self.raise_shakapacker_version_incompatible_for_autobundling
      msg = <<~MSG
        **ERROR** ReactOnRails: Please upgrade Shakapacker to version #{ReactOnRails::PacksGenerator::MINIMUM_SHAKAPACKER_VERSION} or \
        above to use the automated bundle generation feature. The currently installed version is \
        #{ReactOnRails::PackerUtils.shakapacker_version}.
      MSG

      raise ReactOnRails::Error, msg
    end
  end
end

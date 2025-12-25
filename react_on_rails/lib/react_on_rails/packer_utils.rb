# frozen_string_literal: true

require "shakapacker"

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
      @version_checks ||= {}
      @version_checks[required_version] ||= Gem::Version.new(shakapacker_version) >= Gem::Version.new(required_version)
    end

    def self.supports_async_loading?
      shakapacker_version_requirement_met?("8.2.0")
    end

    def self.supports_autobundling?
      min_version = ReactOnRails::PacksGenerator::MINIMUM_SHAKAPACKER_VERSION_FOR_AUTO_BUNDLING
      ::Shakapacker.config.respond_to?(:nested_entries?) && shakapacker_version_requirement_met?(min_version)
    end

    # This returns either a URL for the webpack-dev-server, non-server bundle or
    # the hashed server bundle if using the same bundle for the client.
    # Otherwise returns a file path.
    def self.bundle_js_uri_from_packer(bundle_name)
      hashed_bundle_name = ::Shakapacker.manifest.lookup!(bundle_name)

      # Support for hashing the server-bundle and having that built
      # the webpack-dev-server is provided by the config value
      # "same_bundle_for_client_and_server" where a value of true
      # would mean that the bundle is created by the webpack-dev-server
      is_bundle_running_on_server = bundle_name == ReactOnRails.configuration.server_bundle_js_file

      # Check Pro RSC bundle if Pro is available
      if ReactOnRails::Utils.react_on_rails_pro?
        is_bundle_running_on_server ||= (bundle_name == ReactOnRailsPro.configuration.rsc_bundle_js_file)
      end

      if ::Shakapacker.dev_server.running? && (!is_bundle_running_on_server ||
        ReactOnRails.configuration.same_bundle_for_client_and_server)
        "#{dev_server_url}#{hashed_bundle_name}"
      else
        File.expand_path(File.join("public", hashed_bundle_name)).to_s
      end
    end

    def self.public_output_uri_path
      "#{::Shakapacker.config.public_output_path.relative_path_from(::Shakapacker.config.public_path)}/"
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
      ::Shakapacker.config.source_path
    end

    def self.packer_source_entry_path
      ::Shakapacker.config.source_entry_path
    end

    def self.nested_entries?
      ::Shakapacker.config.nested_entries?
    end

    def self.packer_public_output_path
      ::Shakapacker.config.public_output_path.to_s
    end

    def self.manifest_exists?
      ::Shakapacker.config.public_manifest_path.exist?
    end

    def self.packer_source_path_explicit?
      ::Shakapacker.config.send(:data)[:source_path].present?
    end

    def self.check_manifest_not_cached
      return unless ::Shakapacker.config.cache_manifest?

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
        **ERROR** ReactOnRails: Please upgrade ::Shakapacker to version #{ReactOnRails::PacksGenerator::MINIMUM_SHAKAPACKER_VERSION_FOR_AUTO_BUNDLING} or \
        above to use the automated bundle generation feature (which requires nested_entries support). \
        The currently installed version is #{ReactOnRails::PackerUtils.shakapacker_version}. \
        Basic pack generation requires ::Shakapacker #{ReactOnRails::PacksGenerator::MINIMUM_SHAKAPACKER_VERSION} or above.
      MSG

      raise ReactOnRails::Error, msg
    end

    def self.raise_shakapacker_version_incompatible_for_basic_pack_generation
      msg = <<~MSG
        **ERROR** ReactOnRails: Please upgrade ::Shakapacker to version #{ReactOnRails::PacksGenerator::MINIMUM_SHAKAPACKER_VERSION} or \
        above to use basic pack generation features. The currently installed version is #{ReactOnRails::PackerUtils.shakapacker_version}.
      MSG

      raise ReactOnRails::Error, msg
    end

    # Check if shakapacker.yml has a precompile hook configured
    # This prevents react_on_rails from running generate_packs twice
    #
    # Returns false if detection fails for any reason (missing shakapacker, malformed config, etc.)
    # to ensure generate_packs runs rather than being incorrectly skipped
    #
    # Note: Currently checks a single hook value. Future enhancement will support hook lists
    # to allow prepending/appending multiple commands. See related Shakapacker issue for details.
    def self.shakapacker_precompile_hook_configured?
      return false unless defined?(::Shakapacker)

      hook_value = extract_precompile_hook
      return false if hook_value.nil?

      hook_contains_generate_packs?(hook_value)
    rescue StandardError => e
      # Swallow errors during hook detection to fail safe - if we can't detect the hook,
      # we should run generate_packs rather than skip it incorrectly.
      # Possible errors: NoMethodError (config method missing), TypeError (unexpected data structure),
      # or errors from shakapacker's internal implementation changes
      warn "Warning: Unable to detect shakapacker precompile hook: #{e.message}" if ENV["DEBUG"]
      false
    end

    def self.extract_precompile_hook
      # Access config data using private :data method since there's no public API
      # to access the raw configuration hash needed for hook detection
      config_data = ::Shakapacker.config.send(:data)

      # Try symbol keys first (Shakapacker's internal format), then fall back to string keys
      # The key is 'precompile_hook' at the top level of the config
      config_data&.[](:precompile_hook) || config_data&.[]("precompile_hook")
    end

    def self.hook_contains_generate_packs?(hook_value)
      # The hook value can be either:
      # 1. A direct command containing the rake task
      # 2. A path to a script file that needs to be read
      return false if hook_value.blank?

      # Check if it's a direct command first
      return true if hook_value.to_s.match?(/\breact_on_rails:generate_packs\b/)

      # Check if it's a script file path
      script_path = resolve_hook_script_path(hook_value)
      return false unless script_path && File.exist?(script_path)

      # Read and check script contents
      script_contents = File.read(script_path)
      script_contents.match?(/\breact_on_rails:generate_packs\b/)
    rescue StandardError
      # If we can't read the script, assume it doesn't contain generate_packs
      false
    end

    def self.resolve_hook_script_path(hook_value)
      # Hook value might be a script path relative to Rails root
      return nil unless defined?(Rails) && Rails.respond_to?(:root)

      potential_path = Rails.root.join(hook_value.to_s.strip)
      potential_path if potential_path.file?
    end

    # Returns the configured precompile hook value for logging/debugging
    # Returns nil if no hook is configured
    def self.shakapacker_precompile_hook_value
      return nil unless defined?(::Shakapacker)

      extract_precompile_hook
    rescue StandardError
      nil
    end
  end
end

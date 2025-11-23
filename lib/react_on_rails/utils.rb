# frozen_string_literal: true

require "English"
require "open3"
require "rainbow"
require "active_support"
require "active_support/core_ext/string"
require "shellwords"

# rubocop:disable Metrics/ModuleLength
module ReactOnRails
  module Utils
    TRUNCATION_FILLER = "\n... TRUNCATED #{
      Rainbow('To see the full output, set FULL_TEXT_ERRORS=true.').red
    } ...\n".freeze

    def self.immediate_hydration_pro_license_warning(name, type = "Component")
      "[REACT ON RAILS] Warning: immediate_hydration: true requires a React on Rails Pro license.\n" \
        "#{type} '#{name}' will fall back to standard hydration behavior.\n" \
        "Visit https://www.shakacode.com/react-on-rails-pro/ for licensing information."
    end

    # Normalizes the immediate_hydration option value, enforcing Pro license requirements.
    # Returns the normalized boolean value for immediate_hydration.
    #
    # @param value [Boolean, nil] The immediate_hydration option value
    # @param name [String] The name of the component/store (for warning messages)
    # @param type [String] The type ("Component" or "Store") for warning messages
    # @return [Boolean] The normalized immediate_hydration value
    # @raise [ArgumentError] If value is not a boolean or nil
    #
    # Logic:
    # - Validates that value is true, false, or nil
    # - If value is explicitly true (boolean) and no Pro license: warn and return false
    # - If value is nil: return true for Pro users, false for non-Pro users
    # - Otherwise: return the value as-is (allows explicit false to work)
    def self.normalize_immediate_hydration(value, name, type = "Component")
      # Type validation: only accept boolean or nil
      unless [true, false, nil].include?(value)
        raise ArgumentError,
              "[REACT ON RAILS] immediate_hydration must be true, false, or nil. Got: #{value.inspect} (#{value.class})"
      end

      # Strict equality check: only trigger warning for explicit boolean true
      if value == true && !react_on_rails_pro?
        Rails.logger.warn immediate_hydration_pro_license_warning(name, type)
        return false
      end

      # If nil, default based on Pro license status
      return react_on_rails_pro? if value.nil?

      # Return explicit value (including false)
      value
    end

    # https://forum.shakacode.com/t/yak-of-the-week-ruby-2-4-pathname-empty-changed-to-look-at-file-size/901
    # return object if truthy, else return nil
    def self.truthy_presence(obj)
      if obj.nil? || obj == false
        nil
      else
        obj
      end
    end

    # Wraps message and makes it colored.
    # Pass in the msg and color as a symbol.
    def self.wrap_message(msg, color = :red)
      wrapper_line = ("=" * 80).to_s
      fenced_msg = <<~MSG
        #{wrapper_line}
        #{msg.strip}
        #{wrapper_line}
      MSG

      Rainbow(fenced_msg).color(color)
    end

    def self.object_to_boolean(value)
      [true, "true", "yes", 1, "1", "t"].include?(value.instance_of?(String) ? value.downcase : value)
    end

    def self.server_rendering_is_enabled?
      ReactOnRails.configuration.server_bundle_js_file.present?
    end

    # Invokes command, exiting with a detailed message if there's a failure.
    def self.invoke_and_exit_if_failed(cmd, failure_message)
      stdout, stderr, status = Open3.capture3(cmd)
      unless status.success?
        stdout_msg = stdout.present? ? "\nstdout:\n#{stdout.strip}\n" : ""
        stderr_msg = stderr.present? ? "\nstderr:\n#{stderr.strip}\n" : ""
        msg = <<~MSG
          React on Rails FATAL ERROR!
          #{failure_message}
          cmd: #{cmd}
          exitstatus: #{status.exitstatus}#{stdout_msg}#{stderr_msg}
        MSG

        puts wrap_message(msg)
        puts ""
        puts default_troubleshooting_section

        # Rspec catches exit without! in the exit callbacks
        exit!(1)
      end
      [stdout, stderr, status]
    end

    def self.server_bundle_path_is_http?
      server_bundle_js_file_path =~ %r{https?://}
    end

    def self.bundle_js_file_path(bundle_name)
      # Priority order depends on bundle type:
      # SERVER BUNDLES (normal case): Try private non-public locations first, then manifest, then legacy
      # CLIENT BUNDLES (normal case): Try manifest first, then fallback locations
      if bundle_name == "manifest.json"
        # Default to the non-hashed name in the specified output directory, which, for legacy
        # React on Rails, this is the output directory picked up by the asset pipeline.
        # For Shakapacker, this is the public output path defined in the (shaka/web)packer.yml file.
        File.join(public_bundles_full_path, bundle_name)
      else
        bundle_js_file_path_with_packer(bundle_name)
      end
    end

    private_class_method def self.bundle_js_file_path_with_packer(bundle_name)
      is_server_bundle = server_bundle?(bundle_name)
      config = ReactOnRails.configuration
      root_path = Rails.root || "."

      # If server bundle and server_bundle_output_path is configured, return that path directly
      if is_server_bundle && config.server_bundle_output_path.present?
        private_server_bundle_path = File.expand_path(File.join(root_path, config.server_bundle_output_path,
                                                                bundle_name))

        # Don't fall back to public directory if enforce_private_server_bundles is enabled
        if config.enforce_private_server_bundles || File.exist?(private_server_bundle_path)
          return private_server_bundle_path
        end
      end

      # Try manifest lookup for all bundles
      begin
        ReactOnRails::PackerUtils.bundle_js_uri_from_packer(bundle_name)
      rescue Shakapacker::Manifest::MissingEntryError
        handle_missing_manifest_entry(bundle_name, is_server_bundle)
      end
    end

    private_class_method def self.server_bundle?(bundle_name)
      config = ReactOnRails.configuration
      return true if bundle_name == config.server_bundle_js_file

      # Check Pro configurations if Pro is available
      if react_on_rails_pro?
        pro_config = ReactOnRailsPro.configuration
        return true if bundle_name == pro_config.rsc_bundle_js_file ||
                       bundle_name == pro_config.react_server_client_manifest_file
      end

      false
    end

    private_class_method def self.handle_missing_manifest_entry(bundle_name, is_server_bundle)
      config = ReactOnRails.configuration
      root_path = Rails.root || "."

      # For server bundles with server_bundle_output_path configured, use that
      if is_server_bundle && config.server_bundle_output_path.present?
        candidate_paths = [File.expand_path(File.join(root_path, config.server_bundle_output_path, bundle_name))]
        unless config.enforce_private_server_bundles
          candidate_paths << File.expand_path(File.join(ReactOnRails::PackerUtils.packer_public_output_path,
                                                        bundle_name))
        end

        candidate_paths.each do |path|
          return path if File.exist?(path)
        end
        return candidate_paths.first
      end

      # For client bundles and server bundles without special config, use packer's public path
      # This returns the environment-specific path configured in shakapacker.yml
      File.expand_path(File.join(ReactOnRails::PackerUtils.packer_public_output_path, bundle_name))
    end

    def self.server_bundle_js_file_path
      return @server_bundle_path if @server_bundle_path && !Rails.env.development?

      bundle_name = ReactOnRails.configuration.server_bundle_js_file
      @server_bundle_path = bundle_js_file_path(bundle_name)
    end

    def self.running_on_windows?
      (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
    end

    def self.rails_version_less_than(version)
      @rails_version_less_than ||= {}

      return @rails_version_less_than[version] if @rails_version_less_than.key?(version)

      @rails_version_less_than[version] = begin
        Gem::Version.new(Rails.version) < Gem::Version.new(version)
      end
    end

    module Required
      def required(arg_name)
        raise ReactOnRails::Error, "#{arg_name} is required"
      end
    end

    def self.prepend_cd_node_modules_directory(cmd)
      "cd \"#{ReactOnRails.configuration.node_modules_location}\" && #{cmd}"
    end

    def self.source_path
      ReactOnRails::PackerUtils.packer_source_path
    end

    def self.using_packer_source_path_is_not_defined_and_custom_node_modules?
      !ReactOnRails::PackerUtils.packer_source_path_explicit? &&
        ReactOnRails.configuration.node_modules_location.present?
    end

    def self.public_bundles_full_path
      ReactOnRails::PackerUtils.packer_public_output_path
    end

    # DEPRECATED: Use public_bundles_full_path for clarity about public vs private bundle paths
    def self.generated_assets_full_path
      public_bundles_full_path
    end

    def self.gem_available?(name)
      Gem.loaded_specs[name].present?
    rescue Gem::LoadError
      false
    rescue StandardError
      begin
        Gem.available?(name).present?
      rescue NoMethodError
        false
      end
    end

    # Checks if React on Rails Pro is installed and licensed.
    # This method validates the license and will raise an exception if invalid.
    #
    # @return [Boolean] true if Pro is available with valid license
    # @raise [ReactOnRailsPro::Error] if license is invalid
    def self.react_on_rails_pro?
      return @react_on_rails_pro if defined?(@react_on_rails_pro)

      @react_on_rails_pro = begin
        return false unless gem_available?("react_on_rails_pro")

        # Guard against edge cases where constant exists but module isn't fully loaded
        require "react_on_rails_pro" unless defined?(ReactOnRailsPro)
        ReactOnRailsPro::Utils.validated_license_data!.present?
      end
    end

    # Return an empty string if React on Rails Pro is not installed
    def self.react_on_rails_pro_version
      return @react_on_rails_pro_version if defined?(@react_on_rails_pro_version)

      @react_on_rails_pro_version = if react_on_rails_pro?
                                      Gem.loaded_specs["react_on_rails_pro"].version.to_s
                                    else
                                      ""
                                    end
    end

    # RSC support detection has been moved to React on Rails Pro
    # See react_on_rails_pro/lib/react_on_rails_pro/utils.rb
    def self.rsc_support_enabled?
      return false unless react_on_rails_pro?

      ReactOnRailsPro::Utils.rsc_support_enabled?
    end

    def self.full_text_errors_enabled?
      ENV["FULL_TEXT_ERRORS"] == "true"
    end

    def self.smart_trim(str, max_length = 1000)
      # From https://stackoverflow.com/a/831583/1009332
      str = str.to_s
      return str if full_text_errors_enabled?
      return str unless str.present? && max_length >= 1
      return str if str.length <= max_length

      return str[0, 1] + TRUNCATION_FILLER if max_length == 1

      midpoint = (str.length / 2.0).ceil
      to_remove = str.length - max_length
      lstrip = (to_remove / 2.0).ceil
      rstrip = to_remove - lstrip
      str[0..(midpoint - lstrip - 1)] + TRUNCATION_FILLER + str[(midpoint + rstrip)..]
    end

    def self.find_most_recent_mtime(files)
      files.reduce(1.year.ago) do |newest_time, file|
        mt = File.mtime(file)
        [mt, newest_time].max
      end
    end

    def self.prepend_to_file_if_text_not_present(file:, text_to_prepend:, regex:)
      if File.exist?(file)
        file_content = File.read(file)

        return if file_content.match(regex)

        content_with_prepended_text = text_to_prepend + file_content
        File.write(file, content_with_prepended_text, mode: "w")
      else
        File.write(file, text_to_prepend, mode: "w+")
      end

      puts "Prepended\n#{text_to_prepend}to #{file}."
    end

    # Detects which package manager is being used.
    # First checks the packageManager field in package.json (Node.js Corepack standard),
    # then falls back to checking for lock files.
    #
    # @return [Symbol] The package manager symbol (:npm, :yarn, :pnpm, :bun)
    def self.detect_package_manager
      manager = detect_package_manager_from_package_json || detect_package_manager_from_lock_files
      manager || :yarn # Default to yarn if no detection succeeds
    end

    # Validates package_name input to prevent command injection
    #
    # @param package_name [String] The package name to validate
    # @raise [ReactOnRails::Error] if package_name contains potentially unsafe characters
    private_class_method def self.validate_package_name!(package_name)
      raise ReactOnRails::Error, "package_name cannot be nil" if package_name.nil?
      raise ReactOnRails::Error, "package_name cannot be empty" if package_name.to_s.strip.empty?

      # Allow valid npm package names: alphanumeric, hyphens, underscores, dots, slashes (for scoped packages)
      # See: https://github.com/npm/validate-npm-package-name
      return if package_name.match?(%r{\A[@a-z0-9][a-z0-9._/-]*\z}i)

      raise ReactOnRails::Error, "Invalid package name: #{package_name.inspect}. " \
                                 "Package names must contain only alphanumeric characters, " \
                                 "hyphens, underscores, dots, and slashes (for scoped packages)."
    end

    # Validates package_name and version inputs to prevent command injection
    #
    # @param package_name [String] The package name to validate
    # @param version [String] The version to validate
    # @raise [ReactOnRails::Error] if inputs contain potentially unsafe characters
    private_class_method def self.validate_package_command_inputs!(package_name, version)
      validate_package_name!(package_name)

      raise ReactOnRails::Error, "version cannot be nil" if version.nil?
      raise ReactOnRails::Error, "version cannot be empty" if version.to_s.strip.empty?

      # Allow valid semver versions and common npm version patterns
      # This allows: 1.2.3, 1.2.3-beta.1, 1.2.3-alpha, etc.
      return if version.match?(/\A[a-z0-9][a-z0-9._-]*\z/i)

      raise ReactOnRails::Error, "Invalid version: #{version.inspect}. " \
                                 "Versions must contain only alphanumeric characters, dots, hyphens, and underscores."
    end

    private_class_method def self.detect_package_manager_from_package_json
      package_json_path = File.join(Rails.root, ReactOnRails.configuration.node_modules_location, "package.json")
      return nil unless File.exist?(package_json_path)

      package_json_data = JSON.parse(File.read(package_json_path))
      return nil unless package_json_data["packageManager"]

      manager_string = package_json_data["packageManager"]
      # Extract manager name from strings like "yarn@3.6.0" or "pnpm@8.0.0"
      manager_name = manager_string.split("@").first
      manager_name.to_sym if %w[npm yarn pnpm bun].include?(manager_name)
    rescue StandardError
      nil
    end

    private_class_method def self.detect_package_manager_from_lock_files
      root = Rails.root
      return :yarn if File.exist?(File.join(root, "yarn.lock"))
      return :pnpm if File.exist?(File.join(root, "pnpm-lock.yaml"))
      return :bun if File.exist?(File.join(root, "bun.lockb"))
      return :npm if File.exist?(File.join(root, "package-lock.json"))

      nil
    end

    # Returns the appropriate install command for the detected package manager.
    # Generates the correct command with exact version syntax.
    #
    # @param package_name [String] The name of the package to install
    # @param version [String] The exact version to install
    # @return [String] The command to run (e.g., "yarn add react-on-rails@16.0.0 --exact")
    def self.package_manager_install_exact_command(package_name, version)
      validate_package_command_inputs!(package_name, version)

      manager = detect_package_manager
      # Escape shell arguments to prevent command injection
      safe_package = Shellwords.escape("#{package_name}@#{version}")

      case manager
      when :pnpm
        "pnpm add #{safe_package} --save-exact"
      when :bun
        "bun add #{safe_package} --exact"
      when :npm
        "npm install #{safe_package} --save-exact"
      else # :yarn or unknown, default to yarn
        "yarn add #{safe_package} --exact"
      end
    end

    # Returns the appropriate remove command for the detected package manager.
    #
    # @param package_name [String] The name of the package to remove
    # @return [String] The command to run (e.g., "yarn remove react-on-rails")
    def self.package_manager_remove_command(package_name)
      validate_package_name!(package_name)

      manager = detect_package_manager
      # Escape shell arguments to prevent command injection
      safe_package = Shellwords.escape(package_name)

      case manager
      when :pnpm
        "pnpm remove #{safe_package}"
      when :bun
        "bun remove #{safe_package}"
      when :npm
        "npm uninstall #{safe_package}"
      else # :yarn or unknown, default to yarn
        "yarn remove #{safe_package}"
      end
    end

    # Converts an absolute path (String or Pathname) to a path relative to Rails.root.
    # If the path is already relative or doesn't contain Rails.root, returns it as-is.
    #
    # This method is used to normalize paths from Shakapacker's privateOutputPath (which is
    # absolute) to relative paths suitable for React on Rails configuration.
    #
    # Note: Absolute paths that don't start with Rails.root are intentionally passed through
    # unchanged. While there's no known use case for server bundles outside Rails.root,
    # this behavior preserves the original path for debugging and error messages.
    #
    # @param path [String, Pathname] The path to normalize
    # @return [String, nil] The relative path as a string, or nil if path is nil
    #
    # @example Converting absolute paths within Rails.root
    #   # Assuming Rails.root is "/app"
    #   normalize_to_relative_path("/app/ssr-generated") # => "ssr-generated"
    #   normalize_to_relative_path("/app/foo/bar")       # => "foo/bar"
    #
    # @example Already relative paths pass through
    #   normalize_to_relative_path("ssr-generated")      # => "ssr-generated"
    #   normalize_to_relative_path("./ssr-generated")    # => "./ssr-generated"
    #
    # @example Absolute paths outside Rails.root (edge case)
    #   normalize_to_relative_path("/other/path/bundles") # => "/other/path/bundles"
    # rubocop:disable Metrics/CyclomaticComplexity
    def self.normalize_to_relative_path(path)
      return nil if path.nil?

      path_str = path.to_s
      rails_root_str = Rails.root.to_s.chomp("/")

      # Treat as "inside Rails.root" only for exact match or a subdirectory
      inside_rails_root = rails_root_str.present? &&
                          (path_str == rails_root_str || path_str.start_with?("#{rails_root_str}/"))

      # If path is within Rails.root, remove that prefix
      if inside_rails_root
        # Remove Rails.root and any leading slash
        path_str.sub(%r{^#{Regexp.escape(rails_root_str)}/?}, "")
      else
        # Path is already relative or outside Rails.root
        # Warn if it's an absolute path outside Rails.root (edge case)
        if path_str.start_with?("/") && !inside_rails_root
          Rails.logger&.warn(
            "ReactOnRails: Detected absolute path outside Rails.root: '#{path_str}'. " \
            "Server bundles are typically stored within Rails.root. " \
            "Verify this is intentional."
          )
        end
        path_str
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    def self.default_troubleshooting_section
      <<~DEFAULT
        📞 Get Help & Support:
           • 🚀 Professional Support: react_on_rails@shakacode.com (fastest resolution)
           • 💬 React + Rails Slack: https://invite.reactrails.com
           • 🆓 GitHub Issues: https://github.com/shakacode/react_on_rails/issues
           • 📖 Discussions: https://github.com/shakacode/react_on_rails/discussions
      DEFAULT
    end
  end
end
# rubocop:enable Metrics/ModuleLength

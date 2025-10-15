# frozen_string_literal: true

require "English"
require "open3"
require "rainbow"
require "active_support"
require "active_support/core_ext/string"

# rubocop:disable Metrics/ModuleLength
module ReactOnRails
  module Utils
    TRUNCATION_FILLER = "\n... TRUNCATED #{
      Rainbow('To see the full output, set FULL_TEXT_ERRORS=true.').red
    } ...\n".freeze

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
      bundle_name == config.server_bundle_js_file ||
      bundle_name == config.rsc_bundle_js_file ||
      bundle_name == config.react_server_client_manifest_file
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

    def self.rsc_bundle_js_file_path
      return @rsc_bundle_path if @rsc_bundle_path && !Rails.env.development?

      bundle_name = ReactOnRails.configuration.rsc_bundle_js_file
      @rsc_bundle_path = bundle_js_file_path(bundle_name)
    end

    def self.react_client_manifest_file_path
      return @react_client_manifest_path if @react_client_manifest_path && !Rails.env.development?

      file_name = ReactOnRails.configuration.react_client_manifest_file
      @react_client_manifest_path = ReactOnRails::PackerUtils.asset_uri_from_packer(file_name)
    end

    # React Server Manifest is generated by the server bundle.
    # So, it will never be served from the dev server.
    def self.react_server_client_manifest_file_path
      return @react_server_manifest_path if @react_server_manifest_path && !Rails.env.development?

      asset_name = ReactOnRails.configuration.react_server_client_manifest_file
      if asset_name.nil?
        raise ReactOnRails::Error,
              "react_server_client_manifest_file is nil, ensure it is set in your configuration"
      end

      @react_server_manifest_path = bundle_js_file_path(asset_name)
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

    def self.rsc_support_enabled?
      return false unless react_on_rails_pro?

      return @rsc_support_enabled if defined?(@rsc_support_enabled)

      rorp_config = ReactOnRailsPro.configuration
      @rsc_support_enabled = rorp_config.respond_to?(:enable_rsc_support) && rorp_config.enable_rsc_support
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

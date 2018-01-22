# frozen_string_literal: true

require "English"
require "open3"
require "rainbow"
require "active_support"
require "active_support/core_ext/string"

module ReactOnRails
  module Utils
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
      # rubocop:disable Layout/IndentHeredoc
      fenced_msg = <<-MSG
#{wrapper_line}
#{msg.strip}
#{wrapper_line}
      MSG
      # rubocop:enable Layout/IndentHeredoc
      Rainbow(fenced_msg).color(color)
    end

    def self.object_to_boolean(value)
      [true, "true", "yes", 1, "1", "t"].include?(value.class == String ? value.downcase : value)
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
        # rubocop:disable Layout/IndentHeredoc
        msg = <<-MSG
React on Rails FATAL ERROR!
#{failure_message}
cmd: #{cmd}
exitstatus: #{status.exitstatus}#{stdout_msg}#{stderr_msg}
        MSG
        # rubocop:enable Layout/IndentHeredoc
        puts wrap_message(msg)
        exit(1)
      end
      [stdout, stderr, status]
    end

    def self.server_bundle_js_file_path
      # Either:
      # 1. Using same bundle for both server and client, so server bundle will be hashed in manifest
      # 2. Using a different bundle (different Webpack config), so file is not hashed, and
      #    bundle_js_path will throw.
      # 3. Not using webpacker, and bundle_js_path always returns

      # Note, server bundle should not be in the manifest
      # If using webpacker gem per https://github.com/rails/webpacker/issues/571
      return @server_bundle_path if @server_bundle_path && !Rails.env.development?

      bundle_name = ReactOnRails.configuration.server_bundle_js_file
      @server_bundle_path = if using_webpacker?
                              begin
                                bundle_js_file_path(bundle_name)
                              rescue Webpacker::Manifest::MissingEntryError
                                Rails.root.join(File.join(Webpacker.config.public_output_path,
                                                          bundle_name)).to_s
                              end
                            else
                              bundle_js_file_path(bundle_name)
                            end
    end

    def self.bundle_js_file_path(bundle_name)
      if using_webpacker? && bundle_name != "manifest.json"
        bundle_js_file_path_from_webpacker(bundle_name)
      else
        # Default to the non-hashed name in the specified output directory, which, for legacy
        # React on Rails, this is the output directory picked up by the asset pipeline.
        File.join(ReactOnRails.configuration.generated_assets_dir, bundle_name)
      end
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

    def self.rails_version_less_than_4_1_1
      rails_version_less_than("4.1.1")
    end

    module Required
      def required(arg_name)
        raise ArgumentError, "#{arg_name} is required"
      end
    end

    def self.prepend_cd_node_modules_directory(cmd)
      "cd #{ReactOnRails.configuration.node_modules_location} && #{cmd}"
    end

    def self.source_path
      using_webpacker? ? webpacker_source_path : ReactOnRails.configuration.node_modules_location
    end

    def self.generated_assets_dir
      using_webpacker? ? webpacker_public_output_path : ReactOnRails.configuration.generated_assets_dir
    end

    ###########################################################################
    # WEBPACKER WRAPPERS
    ###########################################################################
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

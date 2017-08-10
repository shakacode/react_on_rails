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
      # binding.pry
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
      # Don't ever use the hashed file name?
      # Cases:
      # 1. Using same bundle for both server and client, so server bundle will be hashed
      # 2. Using a different bundle (different Webpack config), so file is not hashed
      bundle_js_file_path(ReactOnRails.configuration.server_bundle_js_file)
    end

    def self.bundle_js_file_path(bundle_name)
      if using_webpacker?
        # Note, server bundle should not be in the manifest
        # If using webpacker gem per https://github.com/rails/webpacker/issues/571
        hashed_name = Webpacker::Manifest.lookup(bundle_name, throw_if_missing: false)
        hashed_name = bundle_name if hashed_name.blank?
        Rails.root.join(File.join(Webpacker::Configuration.output_path, hashed_name)).to_s
      else
        # Else either the file is not in the manifest, so we'll default to the non-hashed name.
        File.join(ReactOnRails.configuration.generated_assets_dir, bundle_name)
      end
    end

    def self.using_webpacker?
      ActionController::Base.helpers.respond_to?(:asset_pack_path)
    end

    def self.running_on_windows?
      (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
    end

    def self.rails_version_less_than(version)
      @rails_version_less_than ||= {}

      if @rails_version_less_than.key?(version)
        return @rails_version_less_than[version]
      end

      @rails_version_less_than[version] = begin
        Gem::Version.new(Rails.version) < Gem::Version.new(version)
      end
    end

    def self.rails_version_less_than_4_1_1
      rails_version_less_than("4.1.1")
    end

    def self.manifest_exists?
      Webpacker::Configuration.manifest_path.exist?
    end

    module Required
      def required(arg_name)
        raise ArgumentError, "#{arg_name} is required"
      end
    end
  end
end

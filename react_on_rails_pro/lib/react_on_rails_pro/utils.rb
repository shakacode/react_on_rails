# frozen_string_literal: true

# require "English"
# require "open3"
# require "rainbow"
# require "active_support"
# require "active_support/core_ext/string"

module ReactOnRailsPro
  module Utils
    ###########################################################
    # PUBLIC API
    ###########################################################

    def self.rorp_puts(message)
      puts "[ReactOnRailsPro] #{message}"
    end

    def self.copy_assets
      return if ReactOnRailsPro.configuration.assets_to_copy.blank?

      ReactOnRailsPro::Request.upload_assets
    end

    # takes an array of globs, removes excluded_dependency_globs & returns a digest
    def self.digest_of_globs(globs)
      # NOTE: Dir.glob is not stable between machines, even with same OS. So we must sort.
      # .uniq was added to remove redundancies in the case digest_of_globs is used on a union of
      # dependency_globs & source code in order to create a cache key for production bundles
      # We've tested it to make sure that it adds less than a second even in the case of thousands of files
      files = Dir.glob(globs).uniq
      excluded_dependency_globs = ReactOnRailsPro.configuration.excluded_dependency_globs
      if excluded_dependency_globs.present?
        excluded_files = Dir.glob(excluded_dependency_globs).uniq
        files -= excluded_files
      end
      files.sort!

      digest = Digest::MD5.new
      files.each { |f| digest.file(f) unless File.directory?(f) }
      digest
    end

    # Returns a string which should be used as a component in any cache key for
    # react_component or react_component_hash when server rendering. This value is either
    # the server bundle filename with the hash from webpack or an MD5 digest of the
    # entire bundle.
    def self.bundle_hash
      return @bundle_hash if @bundle_hash && !(Rails.env.development? || Rails.env.test?)

      server_bundle_js_file_path = ReactOnRails::Utils.server_bundle_js_file_path

      return @bundle_hash if @bundle_hash && bundle_mtime_same?(server_bundle_js_file_path)

      @bundle_hash = calc_bundle_hash(server_bundle_js_file_path)
    end

    # Returns the hashed file name when using webpacker. Useful for creating cache keys.
    def self.bundle_file_name(bundle_name)
      unless ReactOnRails::PackerUtils.using_packer?
        raise ReactOnRailsPro::Error, "Only call bundle_file_name if using webpacker"
      end

      # bundle_js_uri_from_packer can return a file path or a HTTP URL (for files served from the dev server)
      # Pathname can handle both cases
      full_path = ReactOnRails::PackerUtils.bundle_js_uri_from_packer(bundle_name)
      pathname = Pathname.new(full_path)
      pathname.basename.to_s
    end

    # Returns the hashed file name of the server bundle when using webpacker.
    # Necessary fragment-caching keys.
    def self.server_bundle_file_name
      return @server_bundle_hash if @server_bundle_hash && !Rails.env.development?

      @server_bundle_hash = begin
        server_bundle_name = ReactOnRails.configuration.server_bundle_js_file
        bundle_file_name(server_bundle_name)
      end
    end

    def self.calc_bundle_hash(server_bundle_js_file_path)
      if Rails.env.development? || Rails.env.test?
        @test_dev_server_bundle_mtime = File.mtime(server_bundle_js_file_path)
      end

      server_bundle_basename = Pathname.new(server_bundle_js_file_path).basename.to_s

      if contains_hash?(server_bundle_basename)
        server_bundle_basename
      else
        "#{Digest::MD5.file(server_bundle_js_file_path)}-#{Rails.env}"
      end
    end

    def self.bundle_mtime_same?(server_bundle_js_file_path)
      @test_dev_server_bundle_mtime == File.mtime(server_bundle_js_file_path)
    end

    def self.contains_hash?(server_bundle_basename)
      # TODO: Need to consider if the configuration value has the ".js" on the end.
      ReactOnRails.configuration.server_bundle_js_file != server_bundle_basename
    end

    def self.with_trace(message = nil)
      return yield unless ReactOnRailsPro.configuration.tracing

      start = Time.current
      result = yield
      finish = Time.current

      caller_method = caller(1..1).first
      Rails.logger.info do
        timing = "#{((finish - start) * 1_000).round(1)}ms"
        "[ReactOnRailsPro] PID:#{Process.pid} #{caller_method[/`.*'/][1..-2]}: #{[message, timing].compact.join(', ')}"
      end

      result
    end

    def self.common_form_data
      {
        "gemVersion" => ReactOnRailsPro::VERSION,
        "protocolVersion" => "1.0.0",
        "password" => ReactOnRailsPro.configuration.renderer_password
      }
    end

    def self.mine_type_from_file_name(filename)
      extension = File.extname(filename)
      Rack::Mime.mime_type(extension)
    end

    # TODO: write test
    def self.printable_cache_key(cache_key)
      cache_key.map do |key|
        if key.is_a?(Enumerable)
          printable_cache_key(key)
        elsif key.respond_to?(:cache_key_with_version)
          key.cache_key_with_version
        elsif key.respond_to?(:cache_key)
          key.cache_key
        else
          key.to_s
        end
      end.join("_").underscore
    end
  end
end

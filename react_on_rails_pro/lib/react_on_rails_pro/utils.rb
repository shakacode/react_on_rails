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

    # Returns a string which should be used as a component in any cache key for
    # react_component or react_component_hash. If server rendering, this value either
    # the server bundle filename with the hash from webpack or an MD5 digest of the
    # entire bundle. If server rendering is not used, you still need to configure
    # ReactOnRails.configuration.server_bundle_js_file with a file that contains
    # any JS code for components that you wish to cache.
    def self.bundle_hash
      return @bundle_hash if @bundle_hash && !Rails.env.development?

      @bundle_hash = begin
        server_bundle_js_file_path = ReactOnRails::Utils.server_bundle_js_file_path
        server_bundle_basename = Pathname.new(server_bundle_js_file_path).basename.to_s

        if ReactOnRails.configuration.server_bundle_js_file == server_bundle_basename
          # There is no hash in the name
          Digest::MD5.file(server_bundle_js_file_path)
        else
          # There is a hash already in the name
          server_bundle_basename
        end
      end
    end

    # Returns the hashed file name when using webpacker. Useful for creating cache keys.
    def self.bundle_file_name(bundle_name)
      unless ReactOnRails::WebpackerUtils.using_webpacker?
        raise ReactOnRailsPro::Error, "Only call bundle_file_name if using webpacker"
      end
      full_path = ReactOnRails::WebpackerUtils.bundle_js_file_path_from_webpacker(bundle_name)
      pathname = Pathname.new(full_path)
      pathname.basename.to_s
    end

    # Returns the hashed file name of the server bundle when using webpacker.
    # Nececessary fragment-caching keys.
    def self.server_bundle_file_name
      return @server_bundle_hash if @server_bundle_hash && !Rails.env.development?

      @server_bundle_hash = begin
        server_bundle_name = ReactOnRails.configuration.server_bundle_js_file
        bundle_file_name(server_bundle_name)
      end
    end
  end
end

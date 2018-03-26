require "react_on_rails/utils"

module ReactOnRails
  module ReactComponent
    class Cache
      class << self
        def call(component_name, options)
          cache_key = cache_key(component_name, options)
          Rails.cache.fetch(cache_key) { yield }
        end

        private

        def cache_key(component_name, options)
          cache_keys = Array(options[:cache_key]).join("/")
          result = "react_on_rails/#{component_name}/#{cache_keys}}"
          result += "/#{server_bundle_digest}" if options[:prerender]
          result
        end

        def server_bundle_digest
          "server_bundle-#{ReactOnRails::Utils.server_bundle_file_hash}"
        end
      end
    end
  end
end

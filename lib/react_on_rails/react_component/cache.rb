require "browser"
require "browser/aliases"
Browser::Base.include(Browser::Aliases)

require "react_on_rails/utils"

module ReactOnRails
  module ReactComponent
    class Cache
      class << self
        def cache_if_flagged(component_name, request, options, &block)
          return yield block unless options.cached

          cache_key = cache_key(component_name, request, options)
          Rails.cache.fetch(cache_key) { yield block }
        end

        private

        def cache_key(component_name, request, options)
          result = [
            "react_on_rails",
            component_name,
            props_digest(options),
            device_digest(request)
          ].join("/")
          result += "/#{server_bundle_digest}" if options.prerender
          result
        end

        def device_digest(request)
          browser = Browser.new(request.user_agent)
          device = if browser.device.mobile?
                     "mobile"
                   elsif browser.device.tablet?
                     "tablet"
                   else
                     "desktop"
                   end
          "device-#{device}"
        end

        def props_digest(options)
          "props-#{Digest::MD5.hexdigest(options.props.to_s)}"
        end

        def server_bundle_digest
          "server_bundle-#{ReactOnRails::Utils.server_bundle_file_hash}"
        end
      end
    end
  end
end

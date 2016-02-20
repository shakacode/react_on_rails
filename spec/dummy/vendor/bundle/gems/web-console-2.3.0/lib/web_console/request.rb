module WebConsole
  # Web Console tailored request object.
  class Request < ActionDispatch::Request
    # Configurable set of whitelisted networks.
    cattr_accessor :whitelisted_ips
    @@whitelisted_ips = Whitelist.new

    # Define a vendor MIME type. We can call it using Mime::WEB_CONSOLE_V2 constant.
    Mime::Type.register 'application/vnd.web-console.v2', :web_console_v2

    # Returns whether a request came from a whitelisted IP.
    #
    # For a request to hit Web Console features, it needs to come from a white
    # listed IP.
    def from_whitelited_ip?
      whitelisted_ips.include?(strict_remote_ip)
    end

    # Determines the remote IP using our much stricter whitelist.
    def strict_remote_ip
      GetSecureIp.new(self, whitelisted_ips).to_s
    end

    # Returns whether the request is acceptable.
    def acceptable?
      xhr? && accepts.any? { |mime| Mime::WEB_CONSOLE_V2 == mime }
    end

    private

      class GetSecureIp < ActionDispatch::RemoteIp::GetIp
        def initialize(req, proxies)
          # After rails/rails@07b2ff0 ActionDispatch::RemoteIp::GetIp initializes
          # with a ActionDispatch::Request object instead of plain Rack
          # environment hash. Keep both @req and @env here, so we don't if/else
          # on Rails versions.
          @req      = req
          @env      = req.env
          @check_ip = true
          @proxies  = proxies
        end

        def filter_proxies(ips)
          ips.reject do |ip|
            @proxies.include?(ip)
          end
        end
      end
  end
end

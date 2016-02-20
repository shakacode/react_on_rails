module Turbolinks
  # Changes the response status to 403 Forbidden if all of these conditions are true:
  # - The current request originated from Turbolinks
  # - The request is being redirected to a different domain
  module XDomainBlocker
    private
      def same_origin?(a, b)
        a = URI.parse URI.escape(a)
        b = URI.parse URI.escape(b)
        [a.scheme, a.host, a.port] == [b.scheme, b.host, b.port]
      end

      def abort_xdomain_redirect
        to_uri = response.headers['Location'] || ""
        current = request.headers['X-XHR-Referer'] || ""
        unless to_uri.blank? || current.blank? || same_origin?(current, to_uri)
          self.status = 403
        end
      end
  end
end
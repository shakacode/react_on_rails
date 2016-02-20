module Turbolinks
  # For non-GET requests, sets a request_method cookie containing
  # the request method of the current request. The Turbolinks script
  # will not initialize if this cookie is set.
  module Cookies
    private
      def set_request_method_cookie
        if request.get?
          cookies.delete(:request_method)
        else
          cookies[:request_method] = request.request_method
        end
      end
  end
end

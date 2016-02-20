module Turbolinks
  # Provides a means of using Turbolinks to perform redirects.  The server
  # will respond with a JavaScript call to Turbolinks.visit(url).
  module Redirection
    extend ActiveSupport::Concern
    
    def redirect_via_turbolinks_to(url = {}, response_status = {})
      redirect_to(url, response_status)

      self.status           = 200
      self.response_body    = "Turbolinks.visit('#{location}');"
      response.content_type = Mime::JS
    end
  end
end
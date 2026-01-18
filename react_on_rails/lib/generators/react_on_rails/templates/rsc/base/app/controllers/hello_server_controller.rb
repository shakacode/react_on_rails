# frozen_string_literal: true

# HelloServer Controller - React Server Components
# This controller demonstrates how to render RSC pages with streaming SSR.
# It's the RSC counterpart to HelloWorldController.
#
# ReactOnRailsPro::Stream provides:
# - stream_view_containing_react_components: Streams the view with RSC support
# - Streaming HTML chunks as components render
# - Automatic hydration on the client
#
# For more information, see:
# https://www.shakacode.com/react-on-rails-pro/docs/react-server-components/

class HelloServerController < ApplicationController
  include ReactOnRailsPro::Stream

  def index
    @hello_server_props = {
      name: "React on Rails Pro"
    }

    stream_view_containing_react_components(template: "hello_server/index")
  end
end

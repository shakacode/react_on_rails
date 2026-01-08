# frozen_string_literal: true

# HelloServer Controller - React Server Components
# This controller demonstrates how to render RSC pages with streaming.
# It's the RSC counterpart to HelloWorldController.
#
# Key features:
# - RSCPayloadRenderer: Enables RSC payload generation for this controller
# - AsyncRendering: Enables async rendering with streaming support
# - stream_view_containing_react_components: Streams the view with RSC support
#
# For more information, see:
# https://www.shakacode.com/react-on-rails-pro/docs/react-server-components/

class HelloServerController < ApplicationController
  include ReactOnRailsPro::RSCPayloadRenderer
  include ReactOnRailsPro::AsyncRendering

  # Enable async rendering for the index action
  enable_async_react_rendering only: [:index]

  def index
    # Props passed to the HelloServer component
    @hello_server_props = {
      name: "React on Rails Pro"
    }

    # Stream the view with React Server Components support
    # This enables:
    # - Server-side rendering of async components
    # - Streaming HTML chunks as components render
    # - Automatic hydration on the client
    stream_view_containing_react_components
  end
end

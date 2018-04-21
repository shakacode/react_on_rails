# frozen_string_literal: true

class PagesController < ApplicationController
  include ReactOnRails::Controller

  before_action do
    session[:something_useful] = "REALLY USEFUL"
  end

  before_action :data

  before_action :initialize_shared_store, only: %i[client_side_hello_world_shared_store_controller
                                                   server_side_hello_world_shared_store_controller]

  # See files in spec/dummy/app/views/pages

  private

  def initialize_shared_store
    redux_store("SharedReduxStore", props: @app_props_server_render)
  end

  def data
    xss_payload = { "<script>window.alert('xss1');</script>" => '<script>window.alert("xss2");</script>' }
    # This is the props used by the React component.
    @app_props_server_render = {
      helloWorldData: {
        name: "Mr. Server Side Rendering"
      }.merge(xss_payload)
    }

    @app_props_hello = {
      helloWorldData: {
        name: "Mrs. Client Side Rendering"
      }.merge(xss_payload)
    }

    @app_props_hello_again = {
      helloWorldData: {
        name: "Mrs. Client Side Hello Again"
      }.merge(xss_payload)
    }
  end
end

# frozen_string_literal: true

class PagesController < ApplicationController
  XSS_PAYLOAD = { "<script>window.alert('xss1');</script>" => '<script>window.alert("xss2");</script>' }.freeze
  APP_PROPS_SERVER_RENDER = {
    helloWorldData: {
      name: "Mr. Server Side Rendering"
    }.merge(XSS_PAYLOAD)
  }.freeze

  include ReactOnRails::Controller

  before_action do
    session[:something_useful] = "REALLY USEFUL"
  end

  before_action :data

  before_action :initialize_shared_store, only: %i[client_side_hello_world_shared_store_controller
                                                   server_side_hello_world_shared_store_controller]

  # See files in spec/dummy/app/views/pages

  helper_method :calc_app_props_server_render

  private

  def calc_app_props_server_render
    puts "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    puts "calling slow calc_app_props_server_render"
    puts "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    APP_PROPS_SERVER_RENDER
  end

  def initialize_shared_store
    redux_store("SharedReduxStore", props: @app_props_server_render)
  end

  def data
    # This is the props used by the React component.
    @app_props_server_render = APP_PROPS_SERVER_RENDER

    @app_props_hello = {
      helloWorldData: {
        name: "Mrs. Client Side Rendering"
      }.merge(XSS_PAYLOAD)
    }

    @app_props_hello_again = {
      helloWorldData: {
        name: "Mrs. Client Side Hello Again"
      }.merge(XSS_PAYLOAD)
    }
  end
end

# frozen_string_literal: true

class PagesController < ApplicationController
  XSS_PAYLOAD = { "<script>window.alert('xss1');</script>" => '<script>window.alert("xss2");</script>' }.freeze
  PROPS_NAME = "Mr. Server Side Rendering"

  include ReactOnRails::Controller

  before_action do
    session[:something_useful] = "REALLY USEFUL"
  end

  before_action :data

  before_action :initialize_shared_store, only: %i[client_side_hello_world_shared_store_controller
                                                   server_side_hello_world_shared_store_controller]

  def cached_react_helmet
    render "/pages/pro/cached_react_helmet"
  end

  def loadable_component
    render "/pages/pro/loadable_component"
  end

  def cached_redux_component
    render "/pages/pro/cached_redux_component"
  end

  # See files in spec/dummy/app/views/pages

  helper_method :calc_slow_app_props_server_render

  private

  def calc_slow_app_props_server_render
    msg = <<-MSG.strip_heredoc
      XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
      calling slow calc_slow_app_props_server_render
      XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    MSG
    Rails.logger.info msg
    render_to_string(template: "/pages/pro/serialize_props.json.jbuilder",
                     locals: { name: PROPS_NAME }, format: :json)
  end

  def initialize_shared_store
    redux_store("SharedReduxStore", props: @app_props_server_render)
  end

  def data
    # This is the props used by the React component.
    @app_props_server_render = {
      helloWorldData: {
        name: PROPS_NAME
      }.merge(XSS_PAYLOAD)
    }

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

class PagesController < ApplicationController
  before_action :data

  # See files in spec/dummy/app/views/pages

  private

  def data
    # This is the props used by the React component.
    @app_props_server_render = {
      helloWorldData: {
        name: "Mr. Server Side Rendering"
      }
    }

    @app_props_hello = {
      helloWorldData: {
        name: "Mrs. Client Side Rendering"
      }
    }

    @app_props_hello_again = {
      helloWorldData: {
        name: "Mrs. Client Side Hello Again"
      }
    }
  end
end

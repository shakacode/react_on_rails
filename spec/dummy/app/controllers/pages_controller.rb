class PagesController < ApplicationController
  def index
    # This is the props used by the React component.
    @app_props = {
      helloWorldData: {
        name: "Prop from Rails from server rendering!"
      }
    }
  end
end

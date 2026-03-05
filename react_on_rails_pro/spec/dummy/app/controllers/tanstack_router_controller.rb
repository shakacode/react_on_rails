# frozen_string_literal: true

class TanstackRouterController < ApplicationController
  before_action :data

  rescue_from ReactOnRails::PrerenderError do |err|
    Rails.logger.error(err.message)
    Rails.logger.error(Array(err.backtrace).join("\n"))
    redirect_to client_side_hello_world_path, flash: { error: "Error prerendering in react_on_rails. See server logs." }
  end

  private

  def data
    @app_props_server_render = {
      helloWorldData: {
        name: "Mr. Server Side Rendering"
      }
    }
  end
end

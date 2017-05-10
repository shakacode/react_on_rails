class ReactRouterController < ApplicationController
  before_action :data

  rescue_from ReactOnRails::PrerenderError do |err|
    Rails.logger.error(err.message)
    Rails.logger.error(err.backtrace.join("\n"))
    redirect_to client_side_main_page_path, flash: { error: "Error prerendering in react_on_rails. See server logs." }
  end

  # See files in spec/dummy/app/views/pages

  private

  def data
    # This is the props used by the React component.
    @app_props_server_render = {
      mainPageData: {
        name: "Mr. Server Side Rendering"
      }
    }
  end
end

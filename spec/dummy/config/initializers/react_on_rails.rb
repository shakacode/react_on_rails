# frozen_string_literal: true

# For documentation of parameters see: docs/basics/configuration.md
module RenderingExtension
  # Return a Hash that contains custom values from the view context that will get passed to
  # all calls to react_component and redux_store for rendering
  def self.custom_context(view_context)
    if view_context.controller.is_a?(ActionMailer::Base)
      {}
    else
      {
        somethingUseful: view_context.session[:something_useful]
      }
    end
  end
end

ReactOnRails.configure do |config|
  config.server_bundle_js_file = "server-bundle.js"
  config.random_dom_id = false # default is true

  # config.build_test_command = "yarn run build:test"
  # config.webpack_generated_files = %w[server-bundle.js manifest.json]
  config.rendering_extension = RenderingExtension
end
